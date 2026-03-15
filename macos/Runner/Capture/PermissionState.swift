import AVFoundation
import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

enum PermissionState: String {
  case granted
  case denied
  case notDetermined
  case restricted
  case notGranted   // for screen/accessibility when we can’t distinguish well
}