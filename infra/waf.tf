resource "aws_wafv2_web_acl" "api-cloudfront-waf" {
  name        = "api-cloudfront-waf"
  description = "WAF for api"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "waf-metrics"
    sampled_requests_enabled   = true
  }

  # rule to allow only US and Brazil
  rule {
    name     = "allow-only-us-br"
    priority = 1

    action {
      block {}
    }

    statement {
      not_statement {
        statement {
          geo_match_statement {
            country_codes = ["US", "BR"]
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "allow-only-us-br"
      sampled_requests_enabled   = false
    }
  }

  # 1. AWS Managed IP Reputation List (Standard Managed Rule - $1/mo)
  # This block enables an AWS Managed Rule Group that automatically blocks requests from IP addresses
  # flagged by Amazon's global threat intelligence
  rule {
    name     = "AWS-IPReputationList"
    priority = 10

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "ip-reputation-rule"
      sampled_requests_enabled   = true
    }
  }

  # For SQL DB (XSS attackes) - Unneeded here since this is dynamo
  # rule {
  #   name     = "AWS-AWSManagedRulesCommonRuleSet"
  #   priority = 15
  #
  #   override_action {
  #     none {}
  #   }
  #
  #   statement {
  #     managed_rule_group_statement {
  #       name        = "AWSManagedRulesCommonRuleSet"
  #       vendor_name = "AWS"
  #     }
  #   }
  #
  #   visibility_config {
  #     cloudwatch_metrics_enabled = true
  #     metric_name                = "common-rule-set"
  #     sampled_requests_enabled   = true
  #   }
  # }

  # 2. Rate Limiting Rule (IP-based limit per 1-minute window)
  rule {
    name     = "RateLimit100Per1Min"
    priority = 20

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit                 = 100
        aggregate_key_type    = "IP"
        evaluation_window_sec = 60
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rate-limit-rule"
      sampled_requests_enabled   = true
    }
  }

  # 3. Block Missing User-Agent or Known Script User-Agents
  rule {
    name     = "BlockBadUserAgents"
    priority = 30

    action {
      block {}
    }

    statement {
      or_statement {
        # Missing User-Agent
        statement {
          size_constraint_statement {
            field_to_match {
              single_header {
                name = "user-agent"
              }
            }
            comparison_operator = "EQ"
            size                = 0
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }

        # Common scraper UA strings
        statement {
          regex_pattern_set_reference_statement {
            arn = aws_wafv2_regex_pattern_set.bad_user_agents.arn
            field_to_match {
              single_header {
                name = "user-agent"
              }
            }
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "bad-user-agents-rule"
      sampled_requests_enabled   = true
    }
  }
}

resource "aws_wafv2_regex_pattern_set" "bad_user_agents" {
  provider    = aws.us_east_1 # Ensure this matches your CloudFront WAF provider
  name        = "bad-user-agents-pattern-set"
  description = "Regex patterns for common bot and scraper user agents"
  scope       = "CLOUDFRONT"

  regular_expression {
    regex_string = ".*(python-requests|curl|postmanruntime|go-http-client|scrapy|httpx).*"
  }

  tags = {
    Name = "lead-forge"
  }
}
