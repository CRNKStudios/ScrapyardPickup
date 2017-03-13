//
//  GameViewController.swift
//  ScrapyardPickup
//
//  Created by Spencer Pollock on 2017-02-21.
//  Copyright © 2017 CRNK Studios. All rights reserved.
//

import GLKit
import OpenGLES

func BUFFER_OFFSET(_ i: Int) -> UnsafeRawPointer? {
    return UnsafeRawPointer(bitPattern: i)
}

let UNIFORM_MODELVIEWPROJECTION_MATRIX = 0
let UNIFORM_NORMAL_MATRIX = 1
var uniforms = [GLint](repeating: 0, count: 2)


// MARK: Buttons
enum Buttons: Int
{
    case BUTTON_UP = 0, BUTTON_DOWN, BUTTON_LEFT, BUTTON_RIGHT, BUTTON_MAGNET_POWER
}

class GameViewController: GLKViewController {
    
    // MARK: Properties
    
    var program: GLuint = 0
    
    var modelViewProjectionMatrix:GLKMatrix4 = GLKMatrix4Identity
    var normalMatrix: GLKMatrix3 = GLKMatrix3Identity
    var modelViewProjectionMatrix2:GLKMatrix4 = GLKMatrix4Identity
    var normalMatrix2: GLKMatrix3 = GLKMatrix3Identity

    var rotation: Float = 0.0
    
    var vertexArray: GLuint = 0
    var vertexBuffer: GLuint = 0
    var vertexArray2: GLuint = 0
    var vertexBuffer2: GLuint = 0
    
    var context: EAGLContext? = nil
    var effect: GLKBaseEffect? = nil
    
    var magnetIsOn = false;
    
    var timer = 0.0
    
//    let BUTTON_UP=0,BUTTON_DOWN=2,BUTTON_LEFT=3,BUTTON_RIGHT=4, BUTTON_MAGNET_POWER=5;
    
// MARK: Create objects
    var playerMagnet: PlayerObject = PlayerObject(name: "CraneModel1", tag: "Player", vertices: CraneObject().getVertexArray(), 0.0, 0.0, 0.0, scale: 1.0, baseMatrix: GLKMatrix4Identity)
    var playerCube: GameObject = GameObject(name: "Cube", tag: "Scrap", vertices: CubeObject().getVertexArray(), 0.0, -2.0, 0.0, scale: 1.0, baseMatrix: GLKMatrix4Identity)
    
    @IBOutlet weak var UIButtonUp: UIButton!
    @IBOutlet weak var UIButtonDown: UIButton!
    @IBOutlet weak var UIButtonLeft: UIButton!
    @IBOutlet weak var UIButtonRight: UIButton!
    @IBOutlet weak var UIButtonMagnetPower: UIButton!
    @IBOutlet weak var TimerLabel: UILabel!
    
// MARK: Functions
    deinit {
        self.tearDownGL()
        
        if EAGLContext.current() === self.context {
            EAGLContext.setCurrent(nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.context = EAGLContext(api: .openGLES2)
        
        if !(self.context != nil) {
            print("Failed to create ES context")
        }
        
        let view = self.view as! GLKView
        view.context = self.context!
        view.drawableDepthFormat = .format24
        
        //setup the ui buttons
        initButtons();
        
        self.setupGL()
    }
    
    //connect UI buttons to funtions
    func initButtons(){
        UIButtonUp.tag = Buttons.BUTTON_UP.rawValue;
        UIButtonUp.addTarget(self,action:#selector(buttonClicked),for:.touchUpInside);
        
        UIButtonDown.tag = Buttons.BUTTON_DOWN.rawValue;
        UIButtonDown.addTarget(self,action:#selector(buttonClicked),for:.touchUpInside);
        
        UIButtonLeft.tag = Buttons.BUTTON_LEFT.rawValue;
        UIButtonLeft.addTarget(self,action:#selector(buttonClicked),for:.touchUpInside);
        
        UIButtonRight.tag = Buttons.BUTTON_RIGHT.rawValue;
        UIButtonRight.addTarget(self,action:#selector(buttonClicked),for:.touchUpInside);
        
        UIButtonMagnetPower.tag = Buttons.BUTTON_MAGNET_POWER.rawValue;
        UIButtonMagnetPower.addTarget(self,action:#selector(buttonClicked),for:.touchDown);
        UIButtonMagnetPower.addTarget(self,action:#selector(buttonReleased),for:.touchUpInside);
    }
    
    func buttonClicked(sender:UIButton)
    {
        switch(sender.tag){
        case Buttons.BUTTON_UP.rawValue:
            playerMagnet.moveObject(xMove: 0.0, yMove: 0.0, zMove: -0.1);
            break;
        case Buttons.BUTTON_DOWN.rawValue:
            playerMagnet.moveObject(xMove: 0.0, yMove: 0.0, zMove: 0.1);
            break;
        case Buttons.BUTTON_LEFT.rawValue:
            playerMagnet.moveObject(xMove: -0.1, yMove: 0.0, zMove: 0.0);
            break;
        case Buttons.BUTTON_RIGHT.rawValue:
            playerMagnet.moveObject(xMove: 0.1, yMove: 0.0, zMove: 0.0);
            break;
        case Buttons.BUTTON_MAGNET_POWER.rawValue:
            print("magnet power on");
            
// MARK: Refactor
            var cubeVertexData = playerCube.getVertices();
            glGenVertexArraysOES(1, &vertexArray2)
            glBindVertexArrayOES(vertexArray2)
            
            glGenBuffers(1, &vertexBuffer2)
            glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer2)
            glBindVertexArrayOES(vertexArray2)
            glBufferData(GLenum(GL_ARRAY_BUFFER), GLsizeiptr(MemoryLayout<GLfloat>.size * cubeVertexData.positions.count + MemoryLayout<GLfloat>.size * cubeVertexData.normals.count), nil, GLenum(GL_STATIC_DRAW))
            glBufferSubData(GLenum(GL_ARRAY_BUFFER), 0, GLsizeiptr(MemoryLayout<GLfloat>.size * cubeVertexData.positions.count), &cubeVertexData.positions) // target, offset, size, data
            glBufferSubData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<GLfloat>.size * cubeVertexData.positions.count, GLsizeiptr(MemoryLayout<GLfloat>.size * cubeVertexData.normals.count), &cubeVertexData.normals) // target, offset, size, data
            
            glEnableVertexAttribArray(GLuint(GLKVertexAttrib.position.rawValue))
            glVertexAttribPointer(GLuint(GLKVertexAttrib.position.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, BUFFER_OFFSET(0))
            glEnableVertexAttribArray(GLuint(GLKVertexAttrib.normal.rawValue))
            glVertexAttribPointer(GLuint(GLKVertexAttrib.normal.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 24, BUFFER_OFFSET(12))
            
            //glBindVertexArrayOES(0)
            glDrawArrays(GLenum(GL_TRIANGLES), 0, 36)
            magnetIsOn=true;
            break;
        default:
            break;
        }
        
    }
    
    //Handle UI button Releases
    func buttonReleased(sender:UIButton){
        switch(sender.tag){
        case Buttons.BUTTON_MAGNET_POWER.rawValue:
            print("magnet power off");
            magnetIsOn=false;
            break;
        default:
            break;
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        if self.isViewLoaded && (self.view.window != nil) {
            self.view = nil
            
            self.tearDownGL()
            
            if EAGLContext.current() === self.context {
                EAGLContext.setCurrent(nil)
            }
            self.context = nil
        }
    }
    
    func setupGL() {
        EAGLContext.setCurrent(self.context)
        
        if(self.loadShaders() == false) {
            print("Failed to load shaders")
        }
        
        self.effect = GLKBaseEffect()
        self.effect!.light0.enabled = GLboolean(GL_TRUE)
        self.effect!.light0.diffuseColor = GLKVector4Make(1.0, 0.4, 0.4, 1.0)
        
        glEnable(GLenum(GL_DEPTH_TEST))
        
        glGenVertexArraysOES(1, &vertexArray)
        glBindVertexArrayOES(vertexArray)
        
        
        
        glGenBuffers(1, &vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        //glBufferData(GLenum(GL_ARRAY_BUFFER), GLsizeiptr(MemoryLayout<GLfloat>.size * gCubeVertexData.count), &gCubeVertexData, GLenum(GL_STATIC_DRAW))
        
        
// MARK: Refactor
        //Get the vertex data from the playermagnet object for drawing
        var playerVertexData: Vertex = playerMagnet.getVertices()
        
        glBufferData(GLenum(GL_ARRAY_BUFFER), GLsizeiptr(MemoryLayout<GLfloat>.size * playerVertexData.positions.count + MemoryLayout<GLfloat>.size * playerVertexData.normals.count), nil, GLenum(GL_STATIC_DRAW))
        glBufferSubData(GLenum(GL_ARRAY_BUFFER), 0, MemoryLayout<GLfloat>.size * playerVertexData.positions.count, &playerVertexData.positions);
        glBufferSubData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<GLfloat>.size * playerVertexData.positions.count, MemoryLayout<GLfloat>.size * playerVertexData.normals.count, &playerVertexData.normals);
        
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.position.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.position.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, BUFFER_OFFSET(0))
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.normal.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.normal.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, BUFFER_OFFSET(0))
        
        glBindVertexArrayOES(0)
    }
    
    func tearDownGL() {
        EAGLContext.setCurrent(self.context)
        
        glDeleteBuffers(1, &vertexBuffer)
        glDeleteVertexArraysOES(1, &vertexArray)
        
        self.effect = nil
        
        if program != 0 {
            glDeleteProgram(program)
            program = 0
        }
    }
    
    // MARK: - GLKView and GLKViewController delegate methods
    
    func update() {
        let aspect = fabsf(Float(self.view.bounds.size.width / self.view.bounds.size.height))
        var projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0), aspect, 0.1, 100.0)
        
        self.effect?.transform.projectionMatrix = projectionMatrix
        
        let baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0, -2.0, -4.0)
        //baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, rotation, 0.0, 1.0, 0.0)
        
        // Compute the model view matrix for the object rendered with GLKit
//        var modelViewMatrix = GLKMatrix4MakeTranslation(0.0, 0.0, -1.5)
//        modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, rotation, 1.0, 1.0, 1.0)
//        modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix)
//        
//        self.effect?.transform.modelviewMatrix = modelViewMatrix
        
        // Compute the model view matrix for the object rendered with ES2
        //var modelViewMatrix = GLKMatrix4MakeTranslation(0.0, 0.0, 1.5)
        var modelViewMatrix = playerMagnet.getTranslationMatrix();
        var modelViewMatrix2 = playerCube.getTranslationMatrix();
        modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, 0.5, 0.5, 0.5)
        modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix)
        modelViewMatrix2 = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix2)
        
        projectionMatrix = GLKMatrix4RotateX(projectionMatrix, 0.5);
        let worldTranslationMatrix = GLKMatrix4MakeTranslation(0.0,  0.0, -3.0)
        projectionMatrix = GLKMatrix4Multiply(projectionMatrix, worldTranslationMatrix)
        
        normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), nil)
        normalMatrix2 = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix2), nil)
        
        modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix)
        modelViewProjectionMatrix2 = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix2)
        
        //rotation += Float(self.timeSinceLastUpdate * 0.5)
        self.updateTimer(dt: self.timeSinceLastUpdate)
    }
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glClearColor(0.65, 0.65, 0.65, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT) | GLbitfield(GL_DEPTH_BUFFER_BIT))
        
        glBindVertexArrayOES(vertexArray)
        
        // Render the object with GLKit
        //self.effect?.prepareToDraw()
        
        //glDrawArrays(GLenum(GL_TRIANGLES) , 0, 36)
        
        // Render the object again with ES2
        glUseProgram(program)
        
        withUnsafePointer(to: &modelViewProjectionMatrix, {
            $0.withMemoryRebound(to: Float.self, capacity: 16, {
                glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, $0)
            })
        })
        
        withUnsafePointer(to: &normalMatrix, {
            $0.withMemoryRebound(to: Float.self, capacity: 9, {
                glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, $0)
            })
        })
        
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 2500)
        
        glBindVertexArrayOES(vertexArray2)
        
         withUnsafePointer(to: &modelViewProjectionMatrix2, {
            $0.withMemoryRebound(to: Float.self, capacity: 16, {
                glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, $0)
            })
        })
        
        withUnsafePointer(to: &normalMatrix2, {
            $0.withMemoryRebound(to: Float.self, capacity: 9, {
                glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, $0)
            })
        })

        glDrawArrays(GLenum(GL_TRIANGLES), 0, 36)
    }
    
    // MARK: -  OpenGL ES 2 shader compilation
    
    func loadShaders() -> Bool {
        var vertShader: GLuint = 0
        var fragShader: GLuint = 0
        var vertShaderPathname: String
        var fragShaderPathname: String
        
        // Create shader program.
        program = glCreateProgram()
        
        // Create and compile vertex shader.
        vertShaderPathname = Bundle.main.path(forResource: "Shader", ofType: "vsh")!
        if self.compileShader(&vertShader, type: GLenum(GL_VERTEX_SHADER), file: vertShaderPathname) == false {
            print("Failed to compile vertex shader")
            return false
        }
        
        // Create and compile fragment shader.
        fragShaderPathname = Bundle.main.path(forResource: "Shader", ofType: "fsh")!
        if !self.compileShader(&fragShader, type: GLenum(GL_FRAGMENT_SHADER), file: fragShaderPathname) {
            print("Failed to compile fragment shader")
            return false
        }
        
        // Attach vertex shader to program.
        glAttachShader(program, vertShader)
        
        // Attach fragment shader to program.
        glAttachShader(program, fragShader)
        
        // Bind attribute locations.
        // This needs to be done prior to linking.
        glBindAttribLocation(program, GLuint(GLKVertexAttrib.position.rawValue), "position")
        glBindAttribLocation(program, GLuint(GLKVertexAttrib.normal.rawValue), "normal")
        
        // Link program.
        if !self.linkProgram(program) {
            print("Failed to link program: \(program)")
            
            if vertShader != 0 {
                glDeleteShader(vertShader)
                vertShader = 0
            }
            if fragShader != 0 {
                glDeleteShader(fragShader)
                fragShader = 0
            }
            if program != 0 {
                glDeleteProgram(program)
                program = 0
            }
            
            return false
        }
        
        // Get uniform locations.
        uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(program, "modelViewProjectionMatrix")
        uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(program, "normalMatrix")
        
        // Release vertex and fragment shaders.
        if vertShader != 0 {
            glDetachShader(program, vertShader)
            glDeleteShader(vertShader)
        }
        if fragShader != 0 {
            glDetachShader(program, fragShader)
            glDeleteShader(fragShader)
        }
        
        return true
    }
    
    
    func compileShader(_ shader: inout GLuint, type: GLenum, file: String) -> Bool {
        var status: GLint = 0
        var source: UnsafePointer<Int8>
        do {
            source = try NSString(contentsOfFile: file, encoding: String.Encoding.utf8.rawValue).utf8String!
        } catch {
            print("Failed to load vertex shader")
            return false
        }
        var castSource: UnsafePointer<GLchar>? = UnsafePointer<GLchar>(source)
        
        shader = glCreateShader(type)
        glShaderSource(shader, 1, &castSource, nil)
        glCompileShader(shader)
        
        //#if defined(DEBUG)
        //        var logLength: GLint = 0
        //        glGetShaderiv(shader, GLenum(GL_INFO_LOG_LENGTH), &logLength)
        //        if logLength > 0 {
        //            var log = UnsafeMutablePointer<GLchar>(malloc(Int(logLength)))
        //            glGetShaderInfoLog(shader, logLength, &logLength, log)
        //            NSLog("Shader compile log: \n%s", log)
        //            free(log)
        //        }
        //#endif
        
        glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &status)
        if status == 0 {
            glDeleteShader(shader)
            return false
        }
        return true
    }
    
    func linkProgram(_ prog: GLuint) -> Bool {
        var status: GLint = 0
        glLinkProgram(prog)
        
        //#if defined(DEBUG)
        //        var logLength: GLint = 0
        //        glGetShaderiv(shader, GLenum(GL_INFO_LOG_LENGTH), &logLength)
        //        if logLength > 0 {
        //            var log = UnsafeMutablePointer<GLchar>(malloc(Int(logLength)))
        //            glGetShaderInfoLog(shader, logLength, &logLength, log)
        //            NSLog("Shader compile log: \n%s", log)
        //            free(log)
        //        }
        //#endif
        
        glGetProgramiv(prog, GLenum(GL_LINK_STATUS), &status)
        if status == 0 {
            return false
        }
        
        return true
    }
    
    func validateProgram(prog: GLuint) -> Bool {
        var logLength: GLsizei = 0
        var status: GLint = 0
        
        glValidateProgram(prog)
        glGetProgramiv(prog, GLenum(GL_INFO_LOG_LENGTH), &logLength)
        if logLength > 0 {
            var log: [GLchar] = [GLchar](repeating: 0, count: Int(logLength))
            glGetProgramInfoLog(prog, logLength, &logLength, &log)
            print("Program validate log: \n\(log)")
        }
        
        glGetProgramiv(prog, GLenum(GL_VALIDATE_STATUS), &status)
        var returnVal = true
        if status == 0 {
            returnVal = false
        }
        return returnVal
    }
    
    func updateTimer(dt: TimeInterval) {
        timer = timer + dt;
        self.TimerLabel.text = "Timer: " + (stringFromTimeInterval(interval: timer) as String);
    }
    
    func stringFromTimeInterval(interval: TimeInterval) -> NSString {
        let ti = NSInteger(interval)
        
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)
        
        return NSString(format: "%0.2d:%0.2d:%0.2d",hours,minutes,seconds)
    }
    
}
