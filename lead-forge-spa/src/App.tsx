import { useState } from 'react'
import './App.css'

interface Contact {
  name: string
  email: string
  careLevel: string
  timestamp: Date
}

function App() {
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [careLevel, setCareLevel] = useState('')
  const [submitted, setSubmitted] = useState(false)

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    
    const newContact: Contact = {
      name,
      email,
      careLevel,
      timestamp: new Date(),
    }
    
    console.log('Contact stored:', newContact)
    
    setSubmitted(true)
    setName('')
    setEmail('')
    setCareLevel('')
  }

  return (
    <div className="banner-container">
      <div className="banner">
        <img src="/element-logo.png" alt="Element" className="logo" />
        <h1>Connect with Element</h1>
        <p className="tagline">
          Discover how we can support your needs
        </p>

        <form onSubmit={handleSubmit} className="contact-form">
          <div className="form-group">
            <label htmlFor="name">Name</label>
            <input
              type="text"
              id="name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
              placeholder="Your name"
            />
          </div>

          <div className="form-group">
            <label htmlFor="email">Email</label>
            <input
              type="email"
              id="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              placeholder="you@example.com"
            />
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
            disabled={Boolean(!name || !email || !careLevel)}
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
