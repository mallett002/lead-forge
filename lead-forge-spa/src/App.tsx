import { useState } from 'react'
import './App.css'

interface Contact {
  first: string
  last: string
  email: string
  careLevel: string
  timestamp: string
}

function App() {
  const [first, setFirst] = useState('')
  const [last, setLast] = useState('')
  const [email, setEmail] = useState('')
  const [emailError, setEmailError] = useState('')
  const [careLevel, setCareLevel] = useState('')
  const [submitted, setSubmitted] = useState(false)

  const validateEmail = (email: string): boolean => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    return emailRegex.test(email)
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    const newContact: Contact = {
      first,
      last,
      email,
      careLevel,
      timestamp: new Date().toISOString(),
    }
    
    try {
        const res = await fetch('https://api.farmtotablenearme.com/leads', {
            method: 'POST',
            body: JSON.stringify(newContact),
        });

        if (res.ok) {
            console.log(`Response not ok. status ${res.status}`);
        }
    } catch (error) {
        console.log(`Error creating lead: ${error}`);
    }
    
    setSubmitted(true);
    setFirst('');
    setLast('');
    setEmail('');
    setCareLevel('');
  }

  return (
    <div className="banner-container">
      <div className="banner">
        <img src="/element-logo.png" alt="Element" className="logo" />
        <h1>Connect with Element!</h1>
        <p className="tagline">
          Discover how we can support your needs
        </p>

        <form onSubmit={handleSubmit} className="contact-form">
          <div className="form-group">
            <label htmlFor="first">First Name</label>
            <input
              type="text"
              id="first"
              value={first}
              onChange={(e) => setFirst(e.target.value)}
              required
              placeholder="Joe"
            />
          </div>

          <div className="form-group">
            <label htmlFor="last">Last Name</label>
            <input
              type="text"
              id="last"
              value={last}
              onChange={(e) => setLast(e.target.value)}
              required
              placeholder="Schmoe"
            />
          </div>

          <div className="form-group">
            <label htmlFor="email">Email</label>
            <input
              type="email"
              id="email"
              value={email}
              onChange={(e) => {
                setEmail(e.target.value)
                if (emailError) setEmailError('')
              }}
              onBlur={(e) => {
                if (e.target.value && !validateEmail(e.target.value)) {
                  setEmailError('Please enter a valid email address')
                }
              }}
              required
              placeholder="you@example.com"
            />
            {emailError && <span className="error-message">{emailError}</span>}
          </div>

          <div className="form-group">
            <label htmlFor="careLevel">Level of Care</label>
            <select
              id="careLevel"
              value={careLevel}
              onChange={(e) => setCareLevel(e.target.value)}
              required
            >
              <option value="">Select your level</option>
              <option value="minimal">Minimal</option>
              <option value="moderate">Moderate</option>
              <option value="high">High</option>
            </select>
          </div>

          <button 
            type="submit"
            className="submit-btn"
            disabled={Boolean(!first || !last || !email || !careLevel || !validateEmail(email))}
          >
            {submitted ? 'Sent!' : 'Get in Touch'}
          </button>
        </form>

        {submitted && (
          <p className="success-message">Thanks! We'll be in touch soon.</p>
        )}
      </div>
    </div>
  )
}

export default App
