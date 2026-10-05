
// ---------------------------------------------------------------------------------------------------------------------
// View
// ---------------------------------------------------------------------------------------------------------------------

import Foundation
import UIKit

// ---------------------------------------------------------------------------------------------------------------------
// UMCInputView
// ---------------------------------------------------------------------------------------------------------------------

@IBDesignable
public class UMCInputView: UIControl
{
    
    // -----------------------------------------------------------------------------------------------------------------
    
    public var viewController: AudioUnitViewControllerUMCInput! = nil
    {
        didSet
        {
            baseClass.viewController = viewController
        }
    }
    
    public var audioUnit: Internal_UMC_Input_AudioUnit!
    {
        get
        {
            if (viewController == nil) { return nil }
            return viewController.audioUnit
        }
    }
    
    public var delegate: UMCInputViewDelegate! = nil
    
    // -----------------------------------------------------------------------------------------------------------------
    
    public var baseClass: UMCViewBaseI = UMCViewBaseI()
    
    // -----------------------------------------------------------------------------------------------------------------
    // overrides
    // -----------------------------------------------------------------------------------------------------------------
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        baseClass.initialize()
    }
    
    required public init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        baseClass.initialize()
    }
    
    // -----------------------------------------------------------------------------------------------------------------
    // drawing
    // -----------------------------------------------------------------------------------------------------------------
    
    override open func draw(_ rect: CGRect)
    {
        if (isHidden) { return }
        baseClass.drawUMCI(frame: bounds)
    }
    
    // -----------------------------------------------------------------------------------------------------------------
    
    public func setFocus(_ value: Bool)
    {
        setNeedsDisplay()
    }
    
    // -----------------------------------------------------------------------------------------------------------------
    
    public func setContrast(contrast: CGFloat)
    {
        let inverted: CGFloat = 1.0 - contrast
        baseClass.colorContrast = UIColor(red: inverted, green: inverted, blue: inverted, alpha: 1.0)
        baseClass.colorContrastInverted = UIColor(red: contrast, green: contrast, blue: contrast, alpha: 1.0)
        setNeedsDisplay()
    }
    
    // -----------------------------------------------------------------------------------------------------------------
    
    // called on initialization (and possibly) with parameter automation
    public func setParameter(address: Int, value: Float)
    {
        
        //kInternalUMCInput_Gain = 0,
        if (address < kInternalUMCInput_Inport)
        {
            // gains are ignored / not implemented
        }
        //kInternalUMCInput_Inport = 32,
        else if (address < kInternalUMCInput_Outport)
        {
            let index = address - kInternalUMCInput_Inport
            baseClass._in_ports[index] = Int(value)
        }
        //kInternalUMCInput_Outport = 64,
        else if (address < kInternalUMCInput_Indicator)
        {
            let index = address - kInternalUMCInput_Outport
            baseClass._in_ports[index] = Int(value)
        }
        //kInternalUMCInput_Indicator = 96,
        else if (address < kInternalUMCInput_Reserved)
        {
            let index = address - kInternalUMCInput_Indicator
            baseClass.levels[index] = CGFloat(value)
        }
        //kInternalUMCInput_Reserved = 128,
        
        // draw the connections
        baseClass.makeLines()
        
        switch address
        {
            //case kInternalUMCInput_Gain: break;
            default: break
        }
        
        setNeedsDisplay()
    }
    
    
    // -----------------------------------------------------------------------------------------------------------------

    public func initFromUnit(audioUnit: Internal_UMC_Input_AudioUnit)
    {
        let portCount = audioUnit.getNumPorts()
        let busCount = audioUnit.getNumBusses()
        
        baseClass.numPorts = portCount
        baseClass.numBusses = busCount
        baseClass.makeLines()
        
        setNeedsDisplay()
    }
    
    // -----------------------------------------------------------------------------------------------------------------

    public func setPortNames(names: [String])
    {
        //if names.count > kMaxPorts { return }
        for i in 0..<names.count
        {
            if i >= kMaxPorts { break }
            
            baseClass.hardwareNames[i] = names[i]
        }
        setNeedsDisplay()
    }

    // -----------------------------------------------------------------------------------------------------------------

    public func getConnectionsIn() -> [Int]
    {
        return baseClass._in_ports
    }
    public func getConnectionsOut() -> [Int]
    {
        return baseClass._out_ports
    }

    // -----------------------------------------------------------------------------------------------------------------

    // internal
    private func updateConnections()
    {
        baseClass.updateConnectors()
        
        // main UI can now update and forward the values
        delegate?.onUMCInputViewOption(address: 100, value: 1.0) // connections changed
        
        setNeedsDisplay()
    }

    // -----------------------------------------------------------------------------------------------------------------
    // touch
    // -----------------------------------------------------------------------------------------------------------------
    
    private var scaler: CGFloat = 1.0
    private var hotspotMode: String = ""
    private var startLocation = CGPoint(x: 0, y: 0)
    
    // -----------------------------------------------------------------------------------------------------------------

    private var currentConnecting = ""
    private var currentConnectingIndex = -1

    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        let touch : UITouch! = touches.first! as UITouch
        startLocation = touch.location(in: self)
        
        // translate to current scaling
        startLocation.x = startLocation.x / baseClass.scaling.width
        startLocation.y = startLocation.y / baseClass.scaling.height
        
        setHotspotMode(location: startLocation)
        
        if hotspotMode == ""
        {
            viewController?.touchesLocked = false
            return
        }
        else
        {
            viewController?.touchesLocked = true
        }
        
        /*
        switch hotspotMode
        {
        case "": break;
        default:
            break
        }*/
        
        var hit = false
        // I
        let count = baseClass.numPorts
        for c in 0..<count // baseClass.hotspotPortPaths.count
        {
            if (hotspotMode == "slot \(c)") // in
            {
                //let dropped = baseClass.connectors[c]
                let dragged = baseClass.connectors[c]
                
                dragged.origin = "i"
                dragged._i = c
                //dragged._o = -1 // invalidate

                let anchorX = baseClass.hotspotPortPaths[c].bounds.minX + 15
                let anchorY = baseClass.hotspotPortPaths[c].bounds.minY + 15
                dragged.pi_x = anchorX
                dragged.pi_y = anchorY

                dragged.po_x = startLocation.x
                dragged.po_y = startLocation.y
                
                currentConnecting = "i"
                currentConnectingIndex = c
                hit = true
                
                updateConnections()
                break
             }
        }
        
        /*
        // we do not need this, as it complicates everything
        // O
        for c in 0..<baseClass.hotspotBusportPaths.count
        {
        }
        */
        
        if (hit)
        {}
        else
        {}

        self.setNeedsDisplay()
        sendActions(for: UIControl.Event.touchDown)
    }
    
    // -----------------------------------------------------------------------------------------------------------------
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        touchesMoved(touches, with: event)
               
        /*
        switch hotspotMode
        {
        case "": break;
        default:
            break
        }*/
        
        // DRAW FINAL CONNECTOR
        
        var hit = false
        // O
        var count = baseClass.numBusses * 2
        for c in 0..<count // baseClass.hotspotBusportPaths.count
        {
            if (hotspotMode == "bus \(c)") // out
            {
                if (currentConnecting == "")
                {
                    print("no connecting")
                    //assert(false)
                    break
                }
                else
                {
                    //let dropped = baseClass.connectors[c]
                    let dragged = baseClass.connectors[currentConnectingIndex]
                    
                    /*
                    if (c == currentConnectingIndex && currentConnecting == "o")
                    {
                        // drop on self
                        print("self")
                        dragged._i = -1
                        dropped._o = -1
                        delegate?.onUMCInputViewOption(address: 100, value: 1.0) // connections changed
                        baseClass.updateConnections()
                        break
                    }
                    
                    if (dragged.origin == "o")
                    {
                        // we are in port so we do not allow to connect to other inports
                        print("same row!")
                        dragged._i = -1
                        baseClass.updateConnections()
                        break
                    }
                    */

                    let anchorX = baseClass.hotspotBusportPaths[c].bounds.minX + 15
                    let anchorY = baseClass.hotspotBusportPaths[c].bounds.minY + 15
                    dragged.po_x = anchorX
                    dragged.po_y = anchorY
                    dragged._o = c
                    
                    hit = true
                }
                
                updateConnections()
                break
            }
        }
        // I
        count = baseClass.numPorts
        for c in 0..<count // baseClass.hotspotPortPaths.count
        {
            if (hotspotMode == "slot \(c)") // in
            {
                if (currentConnecting == "")
                {
                    print("no connecting")
                    //assert(false)
                    break
                }
                else
                {
                    let dropped = baseClass.connectors[c]
                    let dragged = baseClass.connectors[currentConnectingIndex]
                    
                    if (c == currentConnectingIndex && currentConnecting == "i")
                    {
                        print("self")
                        dragged._i = -1
                        dropped._o = -1
                        
                        updateConnections()
                        break
                    }

                    if (dragged.origin == "i")
                    {
                        // we are out port so we do not allow to connect to other outports
                        print("same row!")
                        dragged._i = -1
                        dragged._o = -1
                        baseClass.updateConnectors()
                        delegate?.onUMCInputViewOption(address: 100, value: 1.0) // connections changed
                        break
                    }

                    let anchorX = baseClass.hotspotPortPaths[c].bounds.minX + 15
                    let anchorY = baseClass.hotspotPortPaths[c].bounds.minY + 15
                    dragged.pi_x = anchorX
                    dragged.pi_y = anchorY
                    dragged._i = c
                    
                    hit = true
                }
 
                updateConnections()
                break
            }
        }

        
        // FALL THRU
        
        // delete the temporary (invalid) connection
        if (!hit)
        {
            if (currentConnectingIndex != -1)
            {
                baseClass.connectors[currentConnectingIndex].clear()
            }
        }
        else
        {}
        
        currentConnecting = ""
        currentConnectingIndex = -1
        
        hotspotMode = ""
        viewController?.touchesLocked = false
        
        setNeedsDisplay()
        if bounds.contains(startLocation)
        {
            sendActions(for: UIControl.Event.touchUpInside)
        }
        else
        {
            sendActions(for: UIControl.Event.touchUpOutside)
        }
    }
    
    // -----------------------------------------------------------------------------------------------------------------
        
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        
        /*
        if hotspotMode == ""
        {
            return
        }*/
        
        let touch: UITouch! = touches.first! as UITouch
        var newLocation: CGPoint = touch.location(in: self)
        
        // translate to current scaling
        newLocation.x = newLocation.x / baseClass.scaling.width
        newLocation.y = newLocation.y / baseClass.scaling.height
                
        var xval: CGFloat = newLocation.x - startLocation.x
        xval = xval / baseClass.scaling.width
        xval = xval * scaler
        
        var yval: CGFloat = newLocation.y - startLocation.y
        yval = yval / baseClass.scaling.height
        yval = yval * scaler
               
        /*
        switch hotspotMode
        {
        case "blah":
            delegate?.onUMCInputViewParameter(address: 0, value: 0.0)
            break;
        default:
            break
        }*/
        
        
        // DRAW TEMPORARY CONNECTION
        
        setHotspotMode(location: newLocation)
        
        if (currentConnectingIndex != -1)
        {
            baseClass.connectors[currentConnectingIndex].po_x = newLocation.x
            baseClass.connectors[currentConnectingIndex].po_y = newLocation.y
        }
        
        self.setNeedsDisplay()
        sendActions(for: UIControl.Event.valueChanged)
    }
    
    // -----------------------------------------------------------------------------------------------------------------
    
    
    // -----------------------------------------------------------------------------------------------------------------
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        viewController?.touchesLocked = false
        
        touchesEnded(touches, with: event)
        return;
        
        /*
        switch hotspotMode
        {
        case "": break;
        default:
            break
        }
        
        self.setNeedsDisplay()
        sendActions(for: UIControl.Event.touchCancel)
        */
    }
    
    // -----------------------------------------------------------------------------------------------------------------
    // local functions
    // -----------------------------------------------------------------------------------------------------------------
    
    private func setHotspotMode(location: CGPoint)
    {
        hotspotMode = ""
        //print (location)

        /*
        if hitTest(location: location, path: baseClass.hotspotSteroLinkPath)
        {
            hotspotMode = "bla"
        }
        else if hitTest(location: location, path: baseClass.hotspotSteroSeparatedPath)
        {
            hotspotMode = "blah"
        }*/
        
        
        // find the currently touched
        for i in 0..<baseClass.hotspotPortPaths.count
        {
            if hitTest(location: location, path: baseClass.hotspotPortPaths[i])
            {
                hotspotMode = "slot \(i)"
                //debugprint(hotspotMode)
                return
            }
        }
        for i in 0..<baseClass.hotspotBusportPaths.count
        {
            if hitTest(location: location, path: baseClass.hotspotBusportPaths[i])
            {
                hotspotMode = "bus \(i)"
                //debugprint(hotspotMode)
                return
            }
        }
            
        if (!hotspotMode.isEmpty)
        {
            //debugprint(hotspotMode)
        }
    }
    
    // -----------------------------------------------------------------------------------------------------------------
    
    private func hitTest(location: CGPoint, path: UIBezierPath) -> Bool
    {
        if path.contains(location)
        {
            return true
        }
        else
        {
            return false
        }
    }
    
}

// ---------------------------------------------------------------------------------------------------------------------
// PROTOCOL
// ---------------------------------------------------------------------------------------------------------------------

public protocol UMCInputViewDelegate: AnyObject
{
    func onUMCInputViewParameter(address: Int, value: Float) // channel parameters
    func onUMCInputViewOption(address: Int, value: Float) // internal options and switches
}

// ---------------------------------------------------------------------------------------------------------------------
// EOF
// ---------------------------------------------------------------------------------------------------------------------
