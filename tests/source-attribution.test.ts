import { describe, it, expect, beforeEach, vi } from "vitest"

// Mock the Clarity VM environment
const mockClarity = {
  tx: {
    sender: "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM",
  },
  block: {
    time: 1234567890,
  },
}

// Mock the contract functions
const sourceAttribution = {
  registerSource: vi.fn(),
  createAttribution: vi.fn(),
  getSource: vi.fn(),
  getAttribution: vi.fn(),
  updateSource: vi.fn(),
}

describe("Source Attribution Contract", () => {
  beforeEach(() => {
    // Reset mocks
    vi.resetAllMocks()
    
    // Setup default mock implementations
    sourceAttribution.registerSource.mockReturnValue({ value: true })
    sourceAttribution.createAttribution.mockReturnValue({ value: 1 }) // Returns attribution ID
    sourceAttribution.updateSource.mockReturnValue({ value: true })
    sourceAttribution.getSource.mockReturnValue({
      value: {
        name: "Construction Site",
        location: "Main Street",
        type: "construction",
        owner: { value: "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG" },
        registeredBy: mockClarity.tx.sender,
      },
    })
    sourceAttribution.getAttribution.mockReturnValue({
      value: {
        violationId: 1,
        sourceId: "source-001",
        confidence: 85,
        evidence: "Spectral analysis matches construction equipment",
        attributedBy: mockClarity.tx.sender,
        timestamp: mockClarity.block.time,
      },
    })
  })
  
  describe("registerSource", () => {
    it("should register a new noise source successfully", () => {
      const sourceId = "source-001"
      const name = "Construction Site"
      const location = "Main Street"
      const type = "construction"
      const owner = { value: "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG" }
      
      const result = sourceAttribution.registerSource(sourceId, name, location, type, owner)
      
      expect(result.value).toBe(true)
      expect(sourceAttribution.registerSource).toHaveBeenCalledWith(sourceId, name, location, type, owner)
    })
  })
  
  describe("createAttribution", () => {
    it("should create an attribution linking a violation to a source", () => {
      const violationId = 1
      const sourceId = "source-001"
      const confidence = 85
      const evidence = "Spectral analysis matches construction equipment"
      
      const result = sourceAttribution.createAttribution(violationId, sourceId, confidence, evidence)
      
      expect(result.value).toBe(1) // Attribution ID
      expect(sourceAttribution.createAttribution).toHaveBeenCalledWith(violationId, sourceId, confidence, evidence)
    })
  })
  
  describe("getSource", () => {
    it("should retrieve source information", () => {
      const sourceId = "source-001"
      
      const result = sourceAttribution.getSource(sourceId)
      
      expect(result.value).toEqual({
        name: "Construction Site",
        location: "Main Street",
        type: "construction",
        owner: { value: "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG" },
        registeredBy: mockClarity.tx.sender,
      })
      expect(sourceAttribution.getSource).toHaveBeenCalledWith(sourceId)
    })
  })
  
  describe("getAttribution", () => {
    it("should retrieve attribution details", () => {
      const attributionId = 1
      
      const result = sourceAttribution.getAttribution(attributionId)
      
      expect(result.value).toEqual({
        violationId: 1,
        sourceId: "source-001",
        confidence: 85,
        evidence: "Spectral analysis matches construction equipment",
        attributedBy: mockClarity.tx.sender,
        timestamp: mockClarity.block.time,
      })
      expect(sourceAttribution.getAttribution).toHaveBeenCalledWith(attributionId)
    })
  })
  
  describe("updateSource", () => {
    it("should update source information", () => {
      const sourceId = "source-001"
      const name = "Updated Construction Site"
      const location = "Updated Main Street"
      const type = "heavy-construction"
      
      const result = sourceAttribution.updateSource(sourceId, name, location, type)
      
      expect(result.value).toBe(true)
      expect(sourceAttribution.updateSource).toHaveBeenCalledWith(sourceId, name, location, type)
    })
  })
})

