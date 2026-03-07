import AVFoundation
import CoreAudio
import Foundation

/// Manages audio device detection and selection
final class AudioDeviceManager {
    
    /// Represents an audio input device
    struct AudioDevice: Identifiable, Hashable {
        let id: AudioDeviceID
        let name: String
        let manufacturer: String
        let isInput: Bool
        let isOutput: Bool
        let sampleRate: Double
        let channels: Int
        
        var displayName: String {
            if name.contains("BlackHole") {
                return "🔊 \(name) (System Audio)"
            } else {
                return name
            }
        }
        
        var isBlackHole: Bool {
            name.lowercased().contains("blackhole")
        }
    }
    
    // MARK: - Device Discovery
    
    /// Get all available audio input devices
    func getInputDevices() -> [AudioDevice] {
        var devices: [AudioDevice] = []
        
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize
        )
        
        guard status == noErr else {
            print("❌ Failed to get audio device list size")
            return devices
        }
        
        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
        
        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &deviceIDs
        )
        
        guard status == noErr else {
            print("❌ Failed to get audio devices")
            return devices
        }
        
        for deviceID in deviceIDs {
            if let device = getDeviceInfo(deviceID: deviceID), device.isInput {
                devices.append(device)
            }
        }
        
        print("🎙️ Found \(devices.count) input devices")
        return devices
    }
    
    /// Get information about a specific audio device
    private func getDeviceInfo(deviceID: AudioDeviceID) -> AudioDevice? {
        guard let name = getDeviceName(deviceID: deviceID),
              let manufacturer = getDeviceManufacturer(deviceID: deviceID) else {
            return nil
        }
        
        let isInput = hasInputChannels(deviceID: deviceID)
        let isOutput = hasOutputChannels(deviceID: deviceID)
        let sampleRate = getSampleRate(deviceID: deviceID)
        let channels = getInputChannelCount(deviceID: deviceID)
        
        return AudioDevice(
            id: deviceID,
            name: name,
            manufacturer: manufacturer,
            isInput: isInput,
            isOutput: isOutput,
            sampleRate: sampleRate,
            channels: channels
        )
    }
    
    private func getDeviceName(deviceID: AudioDeviceID) -> String? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var name: CFString?
        var dataSize = UInt32(MemoryLayout<CFString?>.size)
        
        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &name
        )
        
        guard status == noErr, let name = name else {
            return nil
        }
        
        return name as String
    }
    
    private func getDeviceManufacturer(deviceID: AudioDeviceID) -> String? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceManufacturerCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var manufacturer: CFString?
        var dataSize = UInt32(MemoryLayout<CFString?>.size)
        
        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &manufacturer
        )
        
        guard status == noErr, let manufacturer = manufacturer else {
            return "Unknown"
        }
        
        return manufacturer as String
    }
    
    private func hasInputChannels(deviceID: AudioDeviceID) -> Bool {
        getInputChannelCount(deviceID: deviceID) > 0
    }
    
    private func hasOutputChannels(deviceID: AudioDeviceID) -> Bool {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var dataSize: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize
        )
        
        return status == noErr && dataSize > 0
    }
    
    private func getInputChannelCount(deviceID: AudioDeviceID) -> Int {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize
        )
        
        guard status == noErr else {
            return 0
        }
        
        let bufferList = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: 1)
        defer { bufferList.deallocate() }
        
        status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize,
            bufferList
        )
        
        guard status == noErr else {
            return 0
        }
        
        var channelCount = 0
        let buffers = UnsafeMutableAudioBufferListPointer(bufferList)
        for buffer in buffers {
            channelCount += Int(buffer.mNumberChannels)
        }
        
        return channelCount
    }
    
    private func getSampleRate(deviceID: AudioDeviceID) -> Double {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyNominalSampleRate,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var sampleRate: Float64 = 0
        var dataSize = UInt32(MemoryLayout<Float64>.size)
        
        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &sampleRate
        )
        
        return status == noErr ? sampleRate : 44100.0
    }
    
    // MARK: - BlackHole Detection
    
    /// Check if BlackHole is installed
    func isBlackHoleInstalled() -> Bool {
        let devices = getInputDevices()
        let hasBlackHole = devices.contains { $0.isBlackHole }
        
        if hasBlackHole {
            print("✅ BlackHole detected")
        } else {
            print("⚠️ BlackHole not found")
        }
        
        return hasBlackHole
    }
    
    /// Get BlackHole device if available
    func getBlackHoleDevice() -> AudioDevice? {
        let devices = getInputDevices()
        return devices.first { $0.isBlackHole }
    }
    
    /// Get default audio input device
    func getDefaultInputDevice() -> AudioDevice? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var deviceID: AudioDeviceID = 0
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &deviceID
        )
        
        guard status == noErr else {
            print("❌ Failed to get default input device")
            return nil
        }
        
        return getDeviceInfo(deviceID: deviceID)
    }
}
