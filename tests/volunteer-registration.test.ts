import { describe, it, expect, beforeEach } from "vitest"

// Simple mock for testing
const mockContract = {
  admin: "ST1ADMIN",
  volunteers: new Map(),
  
  getAdmin() {
    return this.admin
  },
  
  getVolunteer(id) {
    return this.volunteers.get(id) || null
  },
  
  isVolunteer(id) {
    return this.volunteers.has(id)
  },
  
  registerVolunteer(sender, name, email, skills) {
    if (this.isVolunteer(sender)) {
      return { err: 1 }
    }
    
    this.volunteers.set(sender, {
      name,
      email,
      skills,
      registered: 100, // Mock block height
      active: true,
    })
    
    return { ok: true }
  },
  
  updateSkills(sender, skills) {
    if (!this.isVolunteer(sender)) {
      return { err: 2 }
    }
    
    const volunteer = this.volunteers.get(sender)
    this.volunteers.set(sender, {
      ...volunteer,
      skills,
    })
    
    return { ok: true }
  },
  
  deactivateVolunteer(sender, id) {
    if (sender !== this.admin) {
      return { err: 3 }
    }
    
    if (!this.isVolunteer(id)) {
      return { err: 2 }
    }
    
    const volunteer = this.volunteers.get(id)
    this.volunteers.set(id, {
      ...volunteer,
      active: false,
    })
    
    return { ok: true }
  },
}

describe("Volunteer Registration Contract", () => {
  beforeEach(() => {
    mockContract.admin = "ST1ADMIN"
    mockContract.volunteers = new Map()
  })
  
  it("should register a volunteer", () => {
    const sender = "ST1USER"
    const name = "John Doe"
    const email = "john@example.com"
    const skills = ["Teaching", "Mentoring"]
    
    const result = mockContract.registerVolunteer(sender, name, email, skills)
    
    expect(result).toEqual({ ok: true })
    expect(mockContract.isVolunteer(sender)).toBe(true)
    
    const volunteer = mockContract.getVolunteer(sender)
    expect(volunteer.name).toBe(name)
    expect(volunteer.skills).toEqual(skills)
  })
  
  it("should not register a volunteer twice", () => {
    const sender = "ST1USER"
    const name = "John Doe"
    const email = "john@example.com"
    const skills = ["Teaching", "Mentoring"]
    
    mockContract.registerVolunteer(sender, name, email, skills)
    const result = mockContract.registerVolunteer(sender, name, email, skills)
    
    expect(result).toEqual({ err: 1 })
  })
  
  it("should update volunteer skills", () => {
    const sender = "ST1USER"
    const name = "John Doe"
    const email = "john@example.com"
    const skills = ["Teaching", "Mentoring"]
    const newSkills = ["Teaching", "Mentoring", "Programming"]
    
    mockContract.registerVolunteer(sender, name, email, skills)
    const result = mockContract.updateSkills(sender, newSkills)
    
    expect(result).toEqual({ ok: true })
    
    const volunteer = mockContract.getVolunteer(sender)
    expect(volunteer.skills).toEqual(newSkills)
  })
  
  it("should deactivate a volunteer when admin", () => {
    const sender = "ST1ADMIN"
    const userId = "ST1USER"
    const name = "John Doe"
    const email = "john@example.com"
    const skills = ["Teaching", "Mentoring"]
    
    mockContract.registerVolunteer(userId, name, email, skills)
    const result = mockContract.deactivateVolunteer(sender, userId)
    
    expect(result).toEqual({ ok: true })
    
    const volunteer = mockContract.getVolunteer(userId)
    expect(volunteer.active).toBe(false)
  })
})

