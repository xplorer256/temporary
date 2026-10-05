//
//  swift
//  JAX Environment
//
//  Created by com.digitster on 27.09.26.
//  Copyright © 2026 com.digitster. All rights reserved.
//

// ---------------------------------------------------------------------------------------------------------------------

import UIKit

// ---------------------------------------------------------------------------------------------------------------------

let kMaxPorts = 32
let kMaxStereoBusses = 16

// ---------------------------------------------------------------------------------------------------------------------
// UMCViewBaseI
// ---------------------------------------------------------------------------------------------------------------------

public class UMCViewBaseI : NSObject
{
    
    public var viewController: AudioUnitViewControllerUMCInput! = nil
    public var audioUnit: Internal_UMC_Input_AudioUnit!
    {
        get
        {
            if (viewController == nil) { return nil }
            return viewController.audioUnit
        }
    }
    
    // -----------------------------------------------------------------------------------------------------------------

    public var numPorts = 21 // test
    public var numBusses = 11 // test // bus are always: numPorts / 2 + 1

    public var _in_ports: [Int] = Array(repeating: -1, count: kMaxPorts)
    public var _out_ports: [Int] = Array(repeating: -1, count: kMaxPorts)
    
    // -----------------------------------------------------------------------------------------------------------------

    public func updateConnectors()
    {
        for i in 0..<connectors.count // numPorts ?
        {
            _in_ports[i] = connectors[i]._i
            _out_ports[i] = connectors[i]._o
        }
        traceConnections()
    }
    
    public func makeLines()
    {
        for i in 0..<connectors.count // numPorts ?
        {
            connectors[i]._i = _in_ports[i]
            connectors[i]._o = _out_ports[i]
        }
        //traceConnections()
    }

    public func traceConnections()
    {
        
#if true // DEBUGGING PRINT
        
        let _busses: [Int] = Array(repeating: 0, count: connectors.count)
        print("busses   : ", _busses)
        print("i ports  : ", _in_ports)
        print("o ports  : ", _out_ports)
        print("connected: ", calculateConnections())
        
#endif
        
    }
    

    // -----------------------------------------------------------------------------------------------------------------

    private var _connections: [Int] = Array(repeating: -1, count: kMaxPorts)
    public func calculateConnections() -> [Int]
    {
        // initialize
        for i in 0..<numPorts
        {
            _connections[i] = -1
        }
        
        // iterate all connectors to get real port connections as a flat bus ordered map
        for i in 0..<numPorts
        {
            let index = connectors[i]._o
            if (index >= 0)
            {
                // does not allow multiple connections
                if _connections[index] >= 0
                {
                    let del = _connections[index]
                    for x in 0..<numPorts
                    {
                        if (connectors[x]._i == del)
                        {
                            connectors[x]._i = -1
                            connectors[x]._o = -1
                        }
                    }
                }
                _connections[index] = connectors[i]._i
            }
        }
        return _connections
    }


    // -----------------------------------------------------------------------------------------------------------------
    // Connector
    // -----------------------------------------------------------------------------------------------------------------

    public class Connector
    {
        public var _i = -1 // -1 = disabled, 0 to 32 = connected
        public var _o = -1 // -1 = disabled, 0 to 32 = connected
        
        // for touch & draw

        public var origin = ""

        public var pi_x: CGFloat = 0.0
        public var pi_y: CGFloat = 0.0
        
        public var po_x: CGFloat  = 0.0
        public var po_y: CGFloat  = 0.0
        
        public func clear()
        {
            _i = -1
            _o = -1
        }
    }
    
    public var connectors: [Connector] = Array(repeating: Connector(), count: kMaxPorts)
    
    // -----------------------------------------------------------------------------------------------------------------

    public func initialize()
    {
        makeHotspotsUMCI()
        
        for i in 0..<kMaxStereoBusses
        {
            busNames[i] = "BUS \(i)"
        }
        for i in 0..<kMaxPorts
        {
            hardwareNames[i] = "PORT \(i)"
        }

        for i in 0..<kMaxPorts
        {
            let conn = Connector()
            
            conn.pi_x = hotspotPortPaths[i].bounds.minX + 15.0
            conn.pi_y = hotspotPortPaths[i].bounds.minY + 15.0
            
            conn.po_x = hotspotBusportPaths[i].bounds.minX + 15.0
            conn.po_y = hotspotBusportPaths[i].bounds.minY + 15.0
            
            connectors[i] = conn
        }
    }
    
    // -----------------------------------------------------------------------------------------------------------------

    var colorEmphasize = UIColor(red: 0.749, green: 0.279, blue: 0.503, alpha: 1.000)
    var colorContrast = UIColor(red: 0.807, green: 0.807, blue: 0.807, alpha: 1.000)
    var colorContrastInverted = UIColor(red: 1.0 - 0.807, green: 1.0 - 0.807, blue: 1.0 - 0.807, alpha: 1.000)
    let colorHotspots = UIColor(red: 0.630, green: 0.820, blue: 0.175, alpha: 0.165)

    // -----------------------------------------------------------------------------------------------------------------
    
    var busNames: [String] = Array(repeating: "BUS", count: kMaxStereoBusses)

    var hardwareNames: [String] = Array(repeating: "PORT", count: kMaxPorts)
    var levels: [CGFloat] = Array(repeating: 0.0, count: kMaxPorts)
    
    var hotspotBusportPaths: [UIBezierPath] = Array(repeating: UIBezierPath(), count: kMaxPorts)
    var hotspotPortPaths: [UIBezierPath] = Array(repeating: UIBezierPath(), count: kMaxPorts)

    // -----------------------------------------------------------------------------------------------------------------
    // drawUMCI
    // -----------------------------------------------------------------------------------------------------------------

    public func drawUMCI(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 1024, height: 400),
                         resizing: ResizingBehavior0 = .aspectFit)
    {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!
        
        //// Resize to Target Frame
        context.saveGState()
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 1024, height: 400), target: targetFrame, instance: self)
        context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
        context.scaleBy(x: resizedFrame.width / 1024, y: resizedFrame.height / 400)
        
        for i in 0..<kMaxStereoBusses
        {
            if (i >= numBusses)
            {
                context.saveGState()
                context.setAlpha(0.4)
                context.beginTransparencyLayer(auxiliaryInfo: nil)
            }

            let offset: CGFloat = CGFloat(i * 60)

            let busRect = CGRect(x: 33 + offset, y: 300, width: 60, height: 68)
            context.saveGState()
            context.clip(to: busRect)
            context.translateBy(x: busRect.minX, y: busRect.minY)

            drawSymbolBus(frame: CGRect(origin: .zero, size: busRect.size),
                          resizing: .stretch,
                          labelBus: busNames[i])
            
            context.restoreGState()
            
            if (i >= numBusses)
            {
                context.endTransparencyLayer()
                context.restoreGState()
            }
        }
        
        for i in 0..<kMaxPorts
        {
            if (i >= numPorts)
            {
                context.saveGState()
                context.setAlpha(0.4)
                context.beginTransparencyLayer(auxiliaryInfo: nil)
            }

            let offset: CGFloat = CGFloat(i * 30)
            
            let portRect = CGRect(x: 33 + offset, y: 28, width: 30, height: 134)
            context.saveGState()
            context.clip(to: portRect)
            context.translateBy(x: portRect.minX, y: portRect.minY)

            drawSymbolPort(frame: CGRect(origin: .zero, size: portRect.size),
                           resizing: .stretch,
                           labelPort: hardwareNames[i],
                           valueLevel: levels[i])
            
            context.restoreGState()
            
            if (i >= numPorts)
            {
                context.endTransparencyLayer()
                context.restoreGState()
            }
        }

        
        // -------------------------------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        // draw beziers
        for i in 0..<connectors.count
        {
            let connector = connectors[i]
            if (connector._i == -1 && connector._o == -1)
            {
                continue
            }
            else
            {
                let bezier3Path = UIBezierPath()
                bezier3Path.move(to: CGPoint(x: connector.pi_x, y: connector.pi_y))
                bezier3Path.addLine(to: CGPoint(x: connector.po_x, y: connector.po_y))
                colorEmphasize.setStroke()
                bezier3Path.lineWidth = 2.5
                bezier3Path.lineCapStyle = .round
                bezier3Path.lineJoinStyle = .round
                bezier3Path.stroke()
            }
        }
        
        // -------------------------------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------


        //// Text Drawing
        let textRect = CGRect(x: 399, y: 205, width: 225, height: 49)
        let textTextContent = "ENVIRONMENT \nINPUT MATRIX"
        let textStyle = NSMutableParagraphStyle()
        textStyle.alignment = .center
        let textFontAttributes = [
            .font: UIFont(name: "HelveticaNeue-CondensedBold", size: 17)!,
            .foregroundColor: colorContrast,
            .paragraphStyle: textStyle,
        ] as [NSAttributedString.Key: Any]

        let textTextHeight: CGFloat = textTextContent.boundingRect(with: CGSize(width: textRect.width, height: CGFloat.infinity), options: .usesLineFragmentOrigin, attributes: textFontAttributes, context: nil).height
        context.saveGState()
        context.clip(to: textRect)
        textTextContent.draw(in: CGRect(x: textRect.minX, y: textRect.minY + (textRect.height - textTextHeight) / 2, width: textRect.width, height: textTextHeight), withAttributes: textFontAttributes)
        context.restoreGState()

        
        makeHotspotsUMCI()
                
        context.restoreGState()

    }
    
    // -----------------------------------------------------------------------------------------------------------------

    // sub
    func makeHotspotsUMCI()
    {
        for i in 0..<kMaxPorts
        {
            let offset: CGFloat = CGFloat(i * 30)
            
            //// Hotspot Bus Drawing
            hotspotBusportPaths[i] = UIBezierPath(rect: CGRect(x: 33 + offset, y: 295, width: 30, height: 30))
            //colorHotspots.setFill()
            //hotspotBusportPaths[i].fill()
        }
        
        for i in 0..<kMaxPorts
        {
            let offset: CGFloat = CGFloat(i * 30)
            
            //// Hotspot Port Drawing
            hotspotPortPaths[i] = UIBezierPath(rect: CGRect(x: 33 + offset, y: 137, width: 30, height: 30))
            //colorHotspots.setFill()
            //hotspotPortPaths[i].fill()
        }
    }
    
    // -----------------------------------------------------------------------------------------------------------------
    
#if false
    
    // NOT USED
    public func drawBeziers(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 1024, height: 400),
                            resizing: ResizingBehavior = .aspectFit)
    {
        return;
        
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!
        
        //// Resize to Target Frame
        context.saveGState()
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 30, height: 134), target: targetFrame)
        context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
        context.scaleBy(x: resizedFrame.width / 30, y: resizedFrame.height / 134)

      
        context.restoreGState()

    }
    
#endif
    
    // -----------------------------------------------------------------------------------------------------------------

    public func drawSymbolPort(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 30, height: 134),
                               resizing: ResizingBehavior = .aspectFit,
                               labelPort: String = "DRIVER",
                               valueLevel: CGFloat = 0.508)
    {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!
        
        //// Resize to Target Frame
        context.saveGState()
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 30, height: 134), target: targetFrame)
        context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
        context.scaleBy(x: resizedFrame.width / 30, y: resizedFrame.height / 134)


        //// Color Declarations
        let colorEmphasizeLight = colorEmphasize.withAlphaComponent(0.5)

        //// Variable Declarations
        let valueLevelExpression: CGFloat = valueLevel * 100

        //// port Drawing
        let portPath = UIBezierPath(roundedRect: CGRect(x: 2, y: 2, width: 26, height: 122), cornerRadius: 4)
        colorEmphasizeLight.setFill()
        portPath.fill()
        colorContrast.setStroke()
        portPath.lineWidth = 2.5
        portPath.stroke()


        //// indicator Drawing
        let indicatorPath = UIBezierPath(roundedRect: CGRect(x: 12.5, y: 10, width: 5, height: valueLevelExpression), cornerRadius: 2.5)
        colorEmphasize.setFill()
        indicatorPath.fill()


        //// connector Drawing
        let connectorPath = UIBezierPath(ovalIn: CGRect(x: 8, y: 116, width: 14, height: 14))
        colorEmphasize.setFill()
        connectorPath.fill()
        colorContrast.setStroke()
        connectorPath.lineWidth = 2.5
        connectorPath.stroke()


        //// name Drawing
        context.saveGState()
        context.translateBy(x: 4, y: 114)
        context.rotate(by: -90 * CGFloat.pi/180)

        let nameRect = CGRect(x: 0, y: 0, width: 104, height: 8)
        let nameStyle = NSMutableParagraphStyle()
        nameStyle.alignment = .right
        let nameFontAttributes = [
            .font: UIFont(name: "HelveticaNeue", size: 7)!,
            .foregroundColor: colorContrast,
            .paragraphStyle: nameStyle,
        ] as [NSAttributedString.Key: Any]

        let nameTextHeight: CGFloat = labelPort.boundingRect(with: CGSize(width: nameRect.width, height: CGFloat.infinity), options: .usesLineFragmentOrigin, attributes: nameFontAttributes, context: nil).height
        context.saveGState()
        context.clip(to: nameRect)
        labelPort.draw(in: CGRect(x: nameRect.minX, y: nameRect.minY + (nameRect.height - nameTextHeight) / 2, width: nameRect.width, height: nameTextHeight), withAttributes: nameFontAttributes)
        context.restoreGState()

        context.restoreGState()
        
        context.restoreGState()

    }

    // -----------------------------------------------------------------------------------------------------------------

    public func drawSymbolBus(frame targetFrame: CGRect = CGRect(x: 0, y: 0, width: 60, height: 68),
                              resizing: ResizingBehavior = .aspectFit,
                              labelBus: String = "Bus")
    {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!
        
        //// Resize to Target Frame
        context.saveGState()
        let resizedFrame: CGRect = resizing.apply(rect: CGRect(x: 0, y: 0, width: 60, height: 68), target: targetFrame)
        context.translateBy(x: resizedFrame.minX, y: resizedFrame.minY)
        context.scaleBy(x: resizedFrame.width / 60, y: resizedFrame.height / 68)


        //// Color Declarations
        let colorEmphasizeLight = colorEmphasize.withAlphaComponent(0.5)

        //// bus Drawing
        let busRect = CGRect(x: 2, y: 8, width: 56, height: 58)
        let busPath = UIBezierPath(roundedRect: busRect, cornerRadius: 4)
        colorEmphasizeLight.setFill()
        busPath.fill()
        colorContrast.setStroke()
        busPath.lineWidth = 2.5
        busPath.lineCapStyle = .round
        busPath.lineJoinStyle = .round
        busPath.stroke()
        let busTextContent = "\n"
        let busStyle = NSMutableParagraphStyle()
        busStyle.alignment = .center
        let busFontAttributes = [
            .font: UIFont(name: "HelveticaNeue", size: 8)!,
            .foregroundColor: UIColor.black,
            .paragraphStyle: busStyle,
        ] as [NSAttributedString.Key: Any]

        let busTextHeight: CGFloat = busTextContent.boundingRect(with: CGSize(width: busRect.width, height: CGFloat.infinity), options: .usesLineFragmentOrigin, attributes: busFontAttributes, context: nil).height
        context.saveGState()
        context.clip(to: busRect)
        busTextContent.draw(in: CGRect(x: busRect.minX, y: busRect.minY + (busRect.height - busTextHeight) / 2, width: busRect.width, height: busTextHeight), withAttributes: busFontAttributes)
        context.restoreGState()


        //// connector L Drawing
        let connectorLPath = UIBezierPath(ovalIn: CGRect(x: 8, y: 2, width: 14, height: 14))
        colorEmphasize.setFill()
        connectorLPath.fill()
        colorContrast.setStroke()
        connectorLPath.lineWidth = 2.5
        connectorLPath.stroke()


        //// connector R Drawing
        let connectorRPath = UIBezierPath(ovalIn: CGRect(x: 38, y: 2, width: 14, height: 14))
        colorEmphasize.setFill()
        connectorRPath.fill()
        colorContrast.setStroke()
        connectorRPath.lineWidth = 2.5
        connectorRPath.stroke()


        //// name Drawing
        let nameRect = CGRect(x: 1, y: 28, width: 58, height: 20)
        let nameStyle = NSMutableParagraphStyle()
        nameStyle.alignment = .center
        let nameFontAttributes = [
            .font: UIFont(name: "HelveticaNeue-CondensedBold", size: 10)!,
            .foregroundColor: colorContrast,
            .paragraphStyle: nameStyle,
        ] as [NSAttributedString.Key: Any]

        let nameTextHeight: CGFloat = labelBus.boundingRect(with: CGSize(width: nameRect.width, height: CGFloat.infinity), options: .usesLineFragmentOrigin, attributes: nameFontAttributes, context: nil).height
        context.saveGState()
        context.clip(to: nameRect)
        labelBus.draw(in: CGRect(x: nameRect.minX, y: nameRect.minY + (nameRect.height - nameTextHeight) / 2, width: nameRect.width, height: nameTextHeight), withAttributes: nameFontAttributes)
        context.restoreGState()
        
        context.restoreGState()

    }
    
    // -----------------------------------------------------------------------------------------------------------------

    //@objc(UMCViewBaseIResizingBehavior)
    public enum ResizingBehavior: Int
    {
        case aspectFit /// The content is proportionally resized to fit into the target rectangle.
        case aspectFill /// The content is proportionally resized to completely fill the target rectangle.
        case stretch /// The content is stretched to match the entire target rectangle.
        case center /// The content is centered in the target rectangle, but it is NOT resized.

        public func apply(rect: CGRect, target: CGRect) -> CGRect {
            if rect == target || target == CGRect.zero {
                return rect
            }

            var scales = CGSize.zero
            scales.width = abs(target.width / rect.width)
            scales.height = abs(target.height / rect.height)

            switch self {
                case .aspectFit:
                    scales.width = min(scales.width, scales.height)
                    scales.height = scales.width
                case .aspectFill:
                    scales.width = max(scales.width, scales.height)
                    scales.height = scales.width
                case .stretch:
                    break
                case .center:
                    scales.width = 1
                    scales.height = 1
            }

            var result = rect.standardized
            result.size.width *= scales.width
            result.size.height *= scales.height
            result.origin.x = target.minX + (target.width - result.width) / 2
            result.origin.y = target.minY + (target.height - result.height) / 2
            return result
        }
    }
    
    public enum ResizingBehavior0: Int
    {
        case aspectFit /// The content is proportionally resized to fit into the target rectangle.
        case aspectFill /// The content is proportionally resized to completely fill the target rectangle.
        case stretch /// The content is stretched to match the entire target rectangle.
        case center /// The content is centered in the target rectangle, but it is NOT resized.

        public func apply(rect: CGRect, target: CGRect, instance: UMCViewBaseI) -> CGRect {
            if rect == target || target == CGRect.zero {
                return rect
            }

            var scales = CGSize.zero
            scales.width = abs(target.width / rect.width)
            scales.height = abs(target.height / rect.height)

            switch self {
                case .aspectFit:
                    scales.width = min(scales.width, scales.height)
                    scales.height = scales.width
                case .aspectFill:
                    scales.width = max(scales.width, scales.height)
                    scales.height = scales.width
                case .stretch:
                    break
                case .center:
                    scales.width = 1
                    scales.height = 1
            }
            
            instance.scaling = scales

            var result = rect.standardized
            result.size.width *= scales.width
            result.size.height *= scales.height
            result.origin.x = target.minX + (target.width - result.width) / 2
            result.origin.y = target.minY + (target.height - result.height) / 2
            return result
        }
    }
    
    public var scaling = CGSize(width: 1.0, height: 1.0)

}

// ---------------------------------------------------------------------------------------------------------------------
// EOF
// ---------------------------------------------------------------------------------------------------------------------
