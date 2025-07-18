import XCTest
@testable import EXIFStripper

final class EXIFStripperTests: XCTestCase {
    
    func testEXIFStripperExists() {
        // Basic test to ensure the library loads
        XCTAssertNotNil(EXIFStripper.self)
    }
    
    func testPrivacyAnalysisInitialization() {
        let analysis = PrivacyAnalysis()
        XCTAssertFalse(analysis.hasSensitiveData)
        XCTAssertEqual(analysis.privacyRiskLevel, .none)
    }
    
    // TODO: Add more comprehensive tests with sample images
}
