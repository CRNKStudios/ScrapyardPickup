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
    
    let BUTTON_UP=0,BUTTON_DOWN=2,BUTTON_LEFT=3,BUTTON_RIGHT=4, BUTTON_MAGNET_POWER=5;
    
    
    var playerMagnet: GameObject = GameObject(ObjectVertexData: v_crane, ObjectNormalData: vn_crane, 0.0, 0.0, 0.0);
    var playerCube: GameObject = GameObject(ObjectVertexData: gCubeVertexData, 0.0, -2.0, 0.0);
    
    @IBOutlet weak var UIButtonUp: UIButton!
    @IBOutlet weak var UIButtonDown: UIButton!
    @IBOutlet weak var UIButtonLeft: UIButton!
    @IBOutlet weak var UIButtonRight: UIButton!
    @IBOutlet weak var UIButtonMagnetPower: UIButton!
    @IBOutlet weak var TimerLabel: UILabel!
    
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
        UIButtonUp.tag=BUTTON_UP;
        UIButtonUp.addTarget(self,action:#selector(buttonClicked),for:.touchUpInside);
        
        UIButtonDown.tag=BUTTON_DOWN;
        UIButtonDown.addTarget(self,action:#selector(buttonClicked),for:.touchUpInside);
        
        UIButtonLeft.tag=BUTTON_LEFT;
        UIButtonLeft.addTarget(self,action:#selector(buttonClicked),for:.touchUpInside);
        
        UIButtonRight.tag=BUTTON_RIGHT;
        UIButtonRight.addTarget(self,action:#selector(buttonClicked),for:.touchUpInside);
        
        UIButtonMagnetPower.tag=BUTTON_MAGNET_POWER;
        UIButtonMagnetPower.addTarget(self,action:#selector(buttonClicked),for:.touchDown);
        UIButtonMagnetPower.addTarget(self,action:#selector(buttonReleased),for:.touchUpInside);
    }
    
    func buttonClicked(sender:UIButton)
    {
        switch(sender.tag){
        case BUTTON_UP:
            playerMagnet.moveObject(xMove: 0.0, yMove: 0.0, zMove: -0.1);
            break;
        case BUTTON_DOWN:
            playerMagnet.moveObject(xMove: 0.0, yMove: 0.0, zMove: 0.1);
            break;
        case BUTTON_LEFT:
            playerMagnet.moveObject(xMove: -0.1, yMove: 0.0, zMove: 0.0);
            break;
        case BUTTON_RIGHT:
            playerMagnet.moveObject(xMove: 0.1, yMove: 0.0, zMove: 0.0);
            break;
        case BUTTON_MAGNET_POWER:
            print("magnet power on");
            
            var vertexDataTest = playerCube.getObjectVertexData();
            glGenVertexArraysOES(1, &vertexArray2)
            glBindVertexArrayOES(vertexArray2)
            
            glGenBuffers(1, &vertexBuffer2)
            glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer2)
            glBindVertexArrayOES(vertexArray2)
            glBufferData(GLenum(GL_ARRAY_BUFFER), GLsizeiptr(MemoryLayout<GLfloat>.size * vertexDataTest.count), &vertexDataTest, GLenum(GL_STATIC_DRAW))
            glEnableVertexAttribArray(GLuint(GLKVertexAttrib.position.rawValue))
            glVertexAttribPointer(GLuint(GLKVertexAttrib.position.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 24, BUFFER_OFFSET(0))
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
        case BUTTON_MAGNET_POWER:
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
        
        
        //Get the vertex data from the playermagnet object for drawing
        var vertexDataTest = playerMagnet.getObjectVertexData();
        
        glBufferData(GLenum(GL_ARRAY_BUFFER), GLsizeiptr(MemoryLayout<GLfloat>.size * vertexDataTest.count), &vertexDataTest, GLenum(GL_STATIC_DRAW))
        
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.position.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.position.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 24, BUFFER_OFFSET(0))
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.normal.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.normal.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 24, BUFFER_OFFSET(12))
        
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

var gCubeVertexData: [GLfloat] = [
    // Data layout for each line below is:
    // positionX, positionY, positionZ,     normalX, normalY, normalZ,
    0.5, -0.5, -0.5,        1.0, 0.0, 0.0,
    0.5, 0.5, -0.5,         1.0, 0.0, 0.0,
    0.5, -0.5, 0.5,         1.0, 0.0, 0.0,
    0.5, -0.5, 0.5,         1.0, 0.0, 0.0,
    0.5, 0.5, -0.5,         1.0, 0.0, 0.0,
    0.5, 0.5, 0.5,          1.0, 0.0, 0.0,
    
    0.5, 0.5, -0.5,         0.0, 1.0, 0.0,
    -0.5, 0.5, -0.5,        0.0, 1.0, 0.0,
    0.5, 0.5, 0.5,          0.0, 1.0, 0.0,
    0.5, 0.5, 0.5,          0.0, 1.0, 0.0,
    -0.5, 0.5, -0.5,        0.0, 1.0, 0.0,
    -0.5, 0.5, 0.5,         0.0, 1.0, 0.0,
    
    -0.5, 0.5, -0.5,        -1.0, 0.0, 0.0,
    -0.5, -0.5, -0.5,      -1.0, 0.0, 0.0,
    -0.5, 0.5, 0.5,         -1.0, 0.0, 0.0,
    -0.5, 0.5, 0.5,         -1.0, 0.0, 0.0,
    -0.5, -0.5, -0.5,      -1.0, 0.0, 0.0,
    -0.5, -0.5, 0.5,        -1.0, 0.0, 0.0,
    
    -0.5, -0.5, -0.5,      0.0, -1.0, 0.0,
    0.5, -0.5, -0.5,        0.0, -1.0, 0.0,
    -0.5, -0.5, 0.5,        0.0, -1.0, 0.0,
    -0.5, -0.5, 0.5,        0.0, -1.0, 0.0,
    0.5, -0.5, -0.5,        0.0, -1.0, 0.0,
    0.5, -0.5, 0.5,         0.0, -1.0, 0.0,
    
    0.5, 0.5, 0.5,          0.0, 0.0, 1.0,
    -0.5, 0.5, 0.5,         0.0, 0.0, 1.0,
    0.5, -0.5, 0.5,         0.0, 0.0, 1.0,
    0.5, -0.5, 0.5,         0.0, 0.0, 1.0,
    -0.5, 0.5, 0.5,         0.0, 0.0, 1.0,
    -0.5, -0.5, 0.5,        0.0, 0.0, 1.0,
    
    0.5, -0.5, -0.5,        0.0, 0.0, -1.0,
    -0.5, -0.5, -0.5,      0.0, 0.0, -1.0,
    0.5, 0.5, -0.5,         0.0, 0.0, -1.0,
    0.5, 0.5, -0.5,         0.0, 0.0, -1.0,
    -0.5, -0.5, -0.5,      0.0, 0.0, -1.0,
    -0.5, 0.5, -0.5,        0.0, 0.0, -1.0
]


var v_crane: [GLfloat] = [
    -2.369095,-0.1016,-0.634797,-2.369095,-0.1016,0.634797,-2.452667,-0.1016,0.0,
    -2.369095,-0.1016,0.634797,-2.369095,-0.1016,-0.634797,-2.124072,-0.1016,-1.226334,
    -2.369095,-0.1016,0.634797,-2.124072,-0.1016,-1.226334,-2.124072,-0.1016,1.226334,
    -2.124072,-0.1016,1.226334,-2.124072,-0.1016,-1.226334,-1.734298,-0.1016,-1.734298,
    -2.124072,-0.1016,1.226334,-1.734298,-0.1016,-1.734298,-1.734298,-0.1016,1.734298,
    -1.734298,-0.1016,1.734298,-1.734298,-0.1016,-1.734298,-1.226334,-0.1016,-2.124072,
    -1.734298,-0.1016,1.734298,-1.226334,-0.1016,-2.124072,-1.226334,-0.1016,2.124072,
    -1.226334,-0.1016,2.124072,-1.226334,-0.1016,-2.124072,-0.634797,-0.1016,-2.369095,
    -1.226334,-0.1016,2.124072,-0.634797,-0.1016,-2.369095,-0.634797,-0.1016,2.369095,
    -0.634797,-0.1016,2.369095,-0.634797,-0.1016,-2.369095,0.0,-0.1016,2.452667,
    0.0,-0.1016,2.452667,-0.634797,-0.1016,-2.369095,0.0,-0.1016,-2.452667,
    0.0,-0.1016,2.452667,0.0,-0.1016,-2.452667,0.634797,-0.1016,2.369095,
    0.634797,-0.1016,2.369095,0.0,-0.1016,-2.452667,0.634797,-0.1016,-2.369095,
    0.634797,-0.1016,2.369095,0.634797,-0.1016,-2.369095,1.226334,-0.1016,2.124072,
    1.226334,-0.1016,2.124072,0.634797,-0.1016,-2.369095,1.226334,-0.1016,-2.124072,
    1.226334,-0.1016,2.124072,1.226334,-0.1016,-2.124072,1.734298,-0.1016,1.734298,
    1.734298,-0.1016,1.734298,1.226334,-0.1016,-2.124072,1.734298,-0.1016,-1.734298,
    1.734298,-0.1016,1.734298,1.734298,-0.1016,-1.734298,2.124072,-0.1016,1.226334,
    2.124072,-0.1016,1.226334,1.734298,-0.1016,-1.734298,2.124072,-0.1016,-1.226334,
    2.124072,-0.1016,1.226334,2.124072,-0.1016,-1.226334,2.369095,-0.1016,0.634797,
    2.369095,-0.1016,0.634797,2.124072,-0.1016,-1.226334,2.369095,-0.1016,-0.634797,
    2.369095,-0.1016,0.634797,2.369095,-0.1016,-0.634797,2.452667,-0.1016,0.0,
    -2.369095,0.128587,0.634797,-2.369095,0.128587,-0.634797,-2.452667,0.128587,0.0,
    -2.369095,0.128587,-0.634797,-2.369095,0.128587,0.634797,-2.124072,0.128587,-1.226334,
    -2.124072,0.128587,-1.226334,-2.369095,0.128587,0.634797,-2.124072,0.128587,1.226334,
    -2.124072,0.128587,-1.226334,-2.124072,0.128587,1.226334,-1.734298,0.128587,-1.734298,
    -1.734298,0.128587,-1.734298,-2.124072,0.128587,1.226334,-1.734298,0.128587,1.734298,
    -1.734298,0.128587,-1.734298,-1.734298,0.128587,1.734298,-1.226334,0.128587,-2.124072,
    -1.226334,0.128587,-2.124072,-1.734298,0.128587,1.734298,-1.226334,0.128587,2.124072,
    -1.226334,0.128587,-2.124072,-1.226334,0.128587,2.124072,-0.634797,0.128587,-2.369095,
    -0.634797,0.128587,-2.369095,-1.226334,0.128587,2.124072,-0.634797,0.128587,2.369095,
    -0.634797,0.128587,-2.369095,-0.634797,0.128587,2.369095,0.0,0.128587,2.452667,
    -0.634797,0.128587,-2.369095,0.0,0.128587,2.452667,-0.316665,0.128587,0.0,
    -0.316665,0.128587,0.0,0.0,0.128587,2.452667,-0.305875,0.128587,0.081959,
    -0.305875,0.128587,0.081959,0.0,0.128587,2.452667,-0.27424,0.128587,0.158333,
    -0.27424,0.128587,0.158333,0.0,0.128587,2.452667,-0.223916,0.128587,0.223916,
    -0.223916,0.128587,0.223916,0.0,0.128587,2.452667,-0.158333,0.128587,0.27424,
    -0.158333,0.128587,0.27424,0.0,0.128587,2.452667,-0.081959,0.128587,0.305875,
    -0.081959,0.128587,0.305875,0.0,0.128587,2.452667,0.0,0.128587,0.316665,
    0.0,0.128587,0.316665,0.0,0.128587,2.452667,0.634797,0.128587,2.369095,
    0.0,0.128587,0.316665,0.634797,0.128587,2.369095,0.081959,0.128587,0.305875,
    0.081959,0.128587,0.305875,0.634797,0.128587,2.369095,0.158333,0.128587,0.27424,
    0.158333,0.128587,0.27424,0.634797,0.128587,2.369095,0.223916,0.128587,0.223916,
    0.223916,0.128587,0.223916,0.634797,0.128587,2.369095,0.27424,0.128587,0.158333,
    0.27424,0.128587,0.158333,0.634797,0.128587,2.369095,0.305875,0.128587,0.081959,
    0.305875,0.128587,0.081959,0.634797,0.128587,2.369095,0.316665,0.128587,0.0,
    -0.316665,0.128587,0.0,0.0,0.128587,-2.452667,-0.634797,0.128587,-2.369095,
    0.0,0.128587,-2.452667,-0.316665,0.128587,0.0,-0.305875,0.128587,-0.081959,
    0.0,0.128587,-2.452667,-0.305875,0.128587,-0.081959,-0.27424,0.128587,-0.158333,
    0.0,0.128587,-2.452667,-0.27424,0.128587,-0.158333,-0.223916,0.128587,-0.223916,
    0.0,0.128587,-2.452667,-0.223916,0.128587,-0.223916,-0.158333,0.128587,-0.27424,
    0.0,0.128587,-2.452667,-0.158333,0.128587,-0.27424,-0.081959,0.128587,-0.305875,
    0.0,0.128587,-2.452667,-0.081959,0.128587,-0.305875,0.0,0.128587,-0.316665,
    0.0,0.128587,-2.452667,0.0,0.128587,-0.316665,0.081959,0.128587,-0.305875,
    0.0,0.128587,-2.452667,0.081959,0.128587,-0.305875,0.634797,0.128587,-2.369095,
    0.634797,0.128587,-2.369095,0.081959,0.128587,-0.305875,0.158333,0.128587,-0.27424,
    0.634797,0.128587,-2.369095,0.158333,0.128587,-0.27424,0.223916,0.128587,-0.223916,
    0.634797,0.128587,-2.369095,0.223916,0.128587,-0.223916,0.27424,0.128587,-0.158333,
    0.634797,0.128587,-2.369095,0.27424,0.128587,-0.158333,0.305875,0.128587,-0.081959,
    0.634797,0.128587,-2.369095,0.305875,0.128587,-0.081959,0.316665,0.128587,0.0,
    0.634797,0.128587,-2.369095,0.316665,0.128587,0.0,0.634797,0.128587,2.369095,
    0.634797,0.128587,-2.369095,0.634797,0.128587,2.369095,1.226334,0.128587,2.124072,
    0.634797,0.128587,-2.369095,1.226334,0.128587,2.124072,1.226334,0.128587,-2.124072,
    1.226334,0.128587,-2.124072,1.226334,0.128587,2.124072,1.734298,0.128587,1.734298,
    1.226334,0.128587,-2.124072,1.734298,0.128587,1.734298,1.734298,0.128587,-1.734298,
    1.734298,0.128587,-1.734298,1.734298,0.128587,1.734298,2.124072,0.128587,1.226334,
    1.734298,0.128587,-1.734298,2.124072,0.128587,1.226334,2.124072,0.128587,-1.226334,
    2.124072,0.128587,-1.226334,2.124072,0.128587,1.226334,2.369095,0.128587,0.634797,
    2.124072,0.128587,-1.226334,2.369095,0.128587,0.634797,2.369095,0.128587,-0.634797,
    2.369095,0.128587,-0.634797,2.369095,0.128587,0.634797,2.452667,0.128587,0.0,
    1.226334,0.0,-2.124072,1.734298,-0.1016,-1.734298,1.226334,-0.1016,-2.124072,
    1.734298,-0.1016,-1.734298,1.226334,0.0,-2.124072,1.734298,0.0,-1.734298,
    1.734298,-0.1016,-1.734298,2.124072,0.0,-1.226334,2.124072,-0.1016,-1.226334,
    2.124072,0.0,-1.226334,1.734298,-0.1016,-1.734298,1.734298,0.0,-1.734298,
    2.124072,-0.1016,-1.226334,2.369095,0.0,-0.634797,2.369095,-0.1016,-0.634797,
    2.369095,0.0,-0.634797,2.124072,-0.1016,-1.226334,2.124072,0.0,-1.226334,
    2.369095,-0.1016,-0.634797,2.452667,0.0,0.0,2.452667,-0.1016,0.0,
    2.452667,0.0,0.0,2.369095,-0.1016,-0.634797,2.369095,0.0,-0.634797,
    2.452667,-0.1016,0.0,2.369095,0.0,0.634797,2.369095,-0.1016,0.634797,
    2.369095,0.0,0.634797,2.452667,-0.1016,0.0,2.452667,0.0,0.0,
    2.369095,-0.1016,0.634797,2.124072,0.0,1.226334,2.124072,-0.1016,1.226334,
    2.124072,0.0,1.226334,2.369095,-0.1016,0.634797,2.369095,0.0,0.634797,
    2.124072,-0.1016,1.226334,1.734298,0.0,1.734298,1.734298,-0.1016,1.734298,
    1.734298,0.0,1.734298,2.124072,-0.1016,1.226334,2.124072,0.0,1.226334,
    1.734298,0.0,1.734298,1.226334,-0.1016,2.124072,1.734298,-0.1016,1.734298,
    1.226334,-0.1016,2.124072,1.734298,0.0,1.734298,1.226334,0.0,2.124072,
    1.226334,0.0,2.124072,0.634797,-0.1016,2.369095,1.226334,-0.1016,2.124072,
    0.634797,-0.1016,2.369095,1.226334,0.0,2.124072,0.634797,0.0,2.369095,
    0.634797,0.0,2.369095,0.0,-0.1016,2.452667,0.634797,-0.1016,2.369095,
    0.0,-0.1016,2.452667,0.634797,0.0,2.369095,0.0,0.0,2.452667,
    0.0,0.0,2.452667,-0.634797,-0.1016,2.369095,0.0,-0.1016,2.452667,
    -0.634797,-0.1016,2.369095,0.0,0.0,2.452667,-0.634797,0.0,2.369095,
    -0.634797,0.0,2.369095,-1.226334,-0.1016,2.124072,-0.634797,-0.1016,2.369095,
    -1.226334,-0.1016,2.124072,-0.634797,0.0,2.369095,-1.226334,0.0,2.124072,
    -1.226334,0.0,2.124072,-1.734298,-0.1016,1.734298,-1.226334,-0.1016,2.124072,
    -1.734298,-0.1016,1.734298,-1.226334,0.0,2.124072,-1.734298,0.0,1.734298,
    -2.124072,0.0,1.226334,-1.734298,-0.1016,1.734298,-1.734298,0.0,1.734298,
    -1.734298,-0.1016,1.734298,-2.124072,0.0,1.226334,-2.124072,-0.1016,1.226334,
    -2.369095,0.0,0.634797,-2.124072,-0.1016,1.226334,-2.124072,0.0,1.226334,
    -2.124072,-0.1016,1.226334,-2.369095,0.0,0.634797,-2.369095,-0.1016,0.634797,
    -2.452667,0.0,0.0,-2.369095,-0.1016,0.634797,-2.369095,0.0,0.634797,
    -2.369095,-0.1016,0.634797,-2.452667,0.0,0.0,-2.452667,-0.1016,0.0,
    -2.369095,0.0,-0.634797,-2.452667,-0.1016,0.0,-2.452667,0.0,0.0,
    -2.452667,-0.1016,0.0,-2.369095,0.0,-0.634797,-2.369095,-0.1016,-0.634797,
    -2.124072,0.0,-1.226334,-2.369095,-0.1016,-0.634797,-2.369095,0.0,-0.634797,
    -2.369095,-0.1016,-0.634797,-2.124072,0.0,-1.226334,-2.124072,-0.1016,-1.226334,
    -1.734298,0.0,-1.734298,-2.124072,-0.1016,-1.226334,-2.124072,0.0,-1.226334,
    -2.124072,-0.1016,-1.226334,-1.734298,0.0,-1.734298,-1.734298,-0.1016,-1.734298,
    -1.734298,0.0,-1.734298,-1.226334,-0.1016,-2.124072,-1.734298,-0.1016,-1.734298,
    -1.226334,-0.1016,-2.124072,-1.734298,0.0,-1.734298,-1.226334,0.0,-2.124072,
    -1.226334,0.0,-2.124072,-0.634797,-0.1016,-2.369095,-1.226334,-0.1016,-2.124072,
    -0.634797,-0.1016,-2.369095,-1.226334,0.0,-2.124072,-0.634797,0.0,-2.369095,
    -0.634797,0.0,-2.369095,0.0,-0.1016,-2.452667,-0.634797,-0.1016,-2.369095,
    0.0,-0.1016,-2.452667,-0.634797,0.0,-2.369095,0.0,0.0,-2.452667,
    0.0,0.0,-2.452667,0.634797,-0.1016,-2.369095,0.0,-0.1016,-2.452667,
    0.634797,-0.1016,-2.369095,0.0,0.0,-2.452667,0.634797,0.0,-2.369095,
    0.634797,0.0,-2.369095,1.226334,-0.1016,-2.124072,0.634797,-0.1016,-2.369095,
    1.226334,-0.1016,-2.124072,0.634797,0.0,-2.369095,1.226334,0.0,-2.124072,
    1.226334,0.128587,-2.124072,1.734298,0.0,-1.734298,1.226334,0.0,-2.124072,
    1.734298,0.0,-1.734298,1.226334,0.128587,-2.124072,1.734298,0.128587,-1.734298,
    1.734298,0.0,-1.734298,2.124072,0.128587,-1.226334,2.124072,0.0,-1.226334,
    2.124072,0.128587,-1.226334,1.734298,0.0,-1.734298,1.734298,0.128587,-1.734298,
    2.124072,0.0,-1.226334,2.369095,0.128587,-0.634797,2.369095,0.0,-0.634797,
    2.369095,0.128587,-0.634797,2.124072,0.0,-1.226334,2.124072,0.128587,-1.226334,
    2.369095,0.0,-0.634797,2.452667,0.128587,0.0,2.452667,0.0,0.0,
    2.452667,0.128587,0.0,2.369095,0.0,-0.634797,2.369095,0.128587,-0.634797,
    2.452667,0.0,0.0,2.369095,0.128587,0.634797,2.369095,0.0,0.634797,
    2.369095,0.128587,0.634797,2.452667,0.0,0.0,2.452667,0.128587,0.0,
    2.369095,0.0,0.634797,2.124072,0.128587,1.226334,2.124072,0.0,1.226334,
    2.124072,0.128587,1.226334,2.369095,0.0,0.634797,2.369095,0.128587,0.634797,
    2.124072,0.0,1.226334,1.734298,0.128587,1.734298,1.734298,0.0,1.734298,
    1.734298,0.128587,1.734298,2.124072,0.0,1.226334,2.124072,0.128587,1.226334,
    1.734298,0.128587,1.734298,1.226334,0.0,2.124072,1.734298,0.0,1.734298,
    1.226334,0.0,2.124072,1.734298,0.128587,1.734298,1.226334,0.128587,2.124072,
    1.226334,0.128587,2.124072,0.634797,0.0,2.369095,1.226334,0.0,2.124072,
    0.634797,0.0,2.369095,1.226334,0.128587,2.124072,0.634797,0.128587,2.369095,
    0.634797,0.128587,2.369095,0.0,0.0,2.452667,0.634797,0.0,2.369095,
    0.0,0.0,2.452667,0.634797,0.128587,2.369095,0.0,0.128587,2.452667,
    0.0,0.128587,2.452667,-0.634797,0.0,2.369095,0.0,0.0,2.452667,
    -0.634797,0.0,2.369095,0.0,0.128587,2.452667,-0.634797,0.128587,2.369095,
    -0.634797,0.128587,2.369095,-1.226334,0.0,2.124072,-0.634797,0.0,2.369095,
    -1.226334,0.0,2.124072,-0.634797,0.128587,2.369095,-1.226334,0.128587,2.124072,
    -1.226334,0.128587,2.124072,-1.734298,0.0,1.734298,-1.226334,0.0,2.124072,
    -1.734298,0.0,1.734298,-1.226334,0.128587,2.124072,-1.734298,0.128587,1.734298,
    -2.124072,0.128587,1.226334,-1.734298,0.0,1.734298,-1.734298,0.128587,1.734298,
    -1.734298,0.0,1.734298,-2.124072,0.128587,1.226334,-2.124072,0.0,1.226334,
    -2.369095,0.128587,0.634797,-2.124072,0.0,1.226334,-2.124072,0.128587,1.226334,
    -2.124072,0.0,1.226334,-2.369095,0.128587,0.634797,-2.369095,0.0,0.634797,
    -2.452667,0.128587,0.0,-2.369095,0.0,0.634797,-2.369095,0.128587,0.634797,
    -2.369095,0.0,0.634797,-2.452667,0.128587,0.0,-2.452667,0.0,0.0,
    -2.369095,0.128587,-0.634797,-2.452667,0.0,0.0,-2.452667,0.128587,0.0,
    -2.452667,0.0,0.0,-2.369095,0.128587,-0.634797,-2.369095,0.0,-0.634797,
    -2.124072,0.128587,-1.226334,-2.369095,0.0,-0.634797,-2.369095,0.128587,-0.634797,
    -2.369095,0.0,-0.634797,-2.124072,0.128587,-1.226334,-2.124072,0.0,-1.226334,
    -1.734298,0.128587,-1.734298,-2.124072,0.0,-1.226334,-2.124072,0.128587,-1.226334,
    -2.124072,0.0,-1.226334,-1.734298,0.128587,-1.734298,-1.734298,0.0,-1.734298,
    -1.734298,0.128587,-1.734298,-1.226334,0.0,-2.124072,-1.734298,0.0,-1.734298,
    -1.226334,0.0,-2.124072,-1.734298,0.128587,-1.734298,-1.226334,0.128587,-2.124072,
    -1.226334,0.128587,-2.124072,-0.634797,0.0,-2.369095,-1.226334,0.0,-2.124072,
    -0.634797,0.0,-2.369095,-1.226334,0.128587,-2.124072,-0.634797,0.128587,-2.369095,
    -0.634797,0.128587,-2.369095,0.0,0.0,-2.452667,-0.634797,0.0,-2.369095,
    0.0,0.0,-2.452667,-0.634797,0.128587,-2.369095,0.0,0.128587,-2.452667,
    0.0,0.128587,-2.452667,0.634797,0.0,-2.369095,0.0,0.0,-2.452667,
    0.634797,0.0,-2.369095,0.0,0.128587,-2.452667,0.634797,0.128587,-2.369095,
    0.634797,0.128587,-2.369095,1.226334,0.0,-2.124072,0.634797,0.0,-2.369095,
    1.226334,0.0,-2.124072,0.634797,0.128587,-2.369095,1.226334,0.128587,-2.124072,
    -0.305875,2.932112,0.081959,-0.305875,2.932112,-0.081959,-0.316665,2.932112,0.0,
    -0.305875,2.932112,-0.081959,-0.305875,2.932112,0.081959,-0.27424,2.932112,-0.158333,
    -0.27424,2.932112,-0.158333,-0.305875,2.932112,0.081959,-0.27424,2.932112,0.158333,
    -0.27424,2.932112,-0.158333,-0.27424,2.932112,0.158333,-0.223916,2.932112,-0.223916,
    -0.223916,2.932112,-0.223916,-0.27424,2.932112,0.158333,-0.223916,2.932112,0.223916,
    -0.223916,2.932112,-0.223916,-0.223916,2.932112,0.223916,-0.158333,2.932112,-0.27424,
    -0.158333,2.932112,-0.27424,-0.223916,2.932112,0.223916,-0.158333,2.932112,0.27424,
    -0.158333,2.932112,-0.27424,-0.158333,2.932112,0.27424,-0.081959,2.932112,-0.305875,
    -0.081959,2.932112,-0.305875,-0.158333,2.932112,0.27424,-0.081959,2.932112,0.305875,
    -0.081959,2.932112,-0.305875,-0.081959,2.932112,0.305875,0.0,2.932112,-0.316665,
    0.0,2.932112,-0.316665,-0.081959,2.932112,0.305875,0.0,2.932112,0.316665,
    0.0,2.932112,-0.316665,0.0,2.932112,0.316665,0.081959,2.932112,-0.305875,
    0.081959,2.932112,-0.305875,0.0,2.932112,0.316665,0.081959,2.932112,0.305875,
    0.081959,2.932112,-0.305875,0.081959,2.932112,0.305875,0.158333,2.932112,-0.27424,
    0.158333,2.932112,-0.27424,0.081959,2.932112,0.305875,0.158333,2.932112,0.27424,
    0.158333,2.932112,-0.27424,0.158333,2.932112,0.27424,0.223916,2.932112,-0.223916,
    0.223916,2.932112,-0.223916,0.158333,2.932112,0.27424,0.223916,2.932112,0.223916,
    0.223916,2.932112,-0.223916,0.223916,2.932112,0.223916,0.27424,2.932112,0.158333,
    0.223916,2.932112,-0.223916,0.27424,2.932112,0.158333,0.27424,2.932112,-0.158333,
    0.27424,2.932112,-0.158333,0.27424,2.932112,0.158333,0.305875,2.932112,-0.081959,
    0.305875,2.932112,-0.081959,0.27424,2.932112,0.158333,0.305875,2.932112,0.081959,
    0.305875,2.932112,-0.081959,0.305875,2.932112,0.081959,0.316665,2.932112,0.0,
    0.316665,2.566022,0.0,0.305875,2.566022,-0.081959,0.0,2.607711,0.0,
    0.316665,2.566022,0.0,0.0,2.607711,0.0,0.305875,2.566022,0.081959,
    0.305875,2.566022,-0.081959,0.316665,2.932112,0.0,0.316665,2.566022,0.0,
    0.316665,2.932112,0.0,0.305875,2.566022,-0.081959,0.305875,2.932112,-0.081959,
    0.316665,2.566022,0.0,0.515403,2.537465,-0.138102,0.305875,2.566022,-0.081959,
    0.515403,2.537465,-0.138102,0.316665,2.566022,0.0,0.533585,2.537465,0.0,
    0.316665,0.128587,0.0,0.305875,2.566022,-0.081959,0.316665,2.566022,0.0,
    0.305875,2.566022,-0.081959,0.316665,0.128587,0.0,0.305875,0.128587,-0.081959,
    0.305875,2.566022,-0.081959,0.27424,2.566022,-0.158333,0.0,2.607711,0.0,
    0.305875,2.566022,0.081959,0.0,2.607711,0.0,0.27424,2.566022,0.158333,
    0.316665,2.566022,0.0,0.305875,2.932112,0.081959,0.305875,2.566022,0.081959,
    0.305875,2.932112,0.081959,0.316665,2.566022,0.0,0.316665,2.932112,0.0,
    0.515403,2.537465,0.138102,0.316665,2.566022,0.0,0.305875,2.566022,0.081959,
    0.316665,2.566022,0.0,0.515403,2.537465,0.138102,0.533585,2.537465,0.0,
    0.305875,0.128587,0.081959,0.316665,2.566022,0.0,0.305875,2.566022,0.081959,
    0.316665,2.566022,0.0,0.305875,0.128587,0.081959,0.316665,0.128587,0.0,
    0.305875,2.566022,-0.081959,0.27424,2.932112,-0.158333,0.305875,2.932112,-0.081959,
    0.27424,2.932112,-0.158333,0.305875,2.566022,-0.081959,0.27424,2.566022,-0.158333,
    0.305875,2.566022,-0.081959,0.462098,2.537465,-0.266792,0.27424,2.566022,-0.158333,
    0.462098,2.537465,-0.266792,0.305875,2.566022,-0.081959,0.515403,2.537465,-0.138102,
    0.533585,2.537465,0.0,0.995682,2.331509,-0.266792,0.515403,2.537465,-0.138102,
    0.995682,2.331509,-0.266792,0.533585,2.537465,0.0,1.030806,2.331509,0.0,
    0.27424,0.128587,-0.158333,0.305875,2.566022,-0.081959,0.305875,0.128587,-0.081959,
    0.305875,2.566022,-0.081959,0.27424,0.128587,-0.158333,0.27424,2.566022,-0.158333,
    0.27424,2.566022,-0.158333,0.223916,2.566022,-0.223916,0.0,2.607711,0.0,
    0.27424,2.566022,0.158333,0.0,2.607711,0.0,0.223916,2.566022,0.223916,
    0.305875,2.566022,0.081959,0.27424,2.932112,0.158333,0.27424,2.566022,0.158333,
    0.27424,2.932112,0.158333,0.305875,2.566022,0.081959,0.305875,2.932112,0.081959,
    0.462098,2.537465,0.266792,0.305875,2.566022,0.081959,0.27424,2.566022,0.158333,
    0.305875,2.566022,0.081959,0.462098,2.537465,0.266792,0.515403,2.537465,0.138102,
    0.27424,0.128587,0.158333,0.305875,2.566022,0.081959,0.27424,2.566022,0.158333,
    0.305875,2.566022,0.081959,0.27424,0.128587,0.158333,0.305875,0.128587,0.081959,
    0.995682,2.331509,0.266792,0.533585,2.537465,0.0,0.515403,2.537465,0.138102,
    0.533585,2.537465,0.0,0.995682,2.331509,0.266792,1.030806,2.331509,0.0,
    0.27424,2.566022,-0.158333,0.223916,2.932112,-0.223916,0.27424,2.932112,-0.158333,
    0.223916,2.932112,-0.223916,0.27424,2.566022,-0.158333,0.223916,2.566022,-0.223916,
    0.158333,2.932112,-0.27424,0.223916,2.566022,-0.223916,0.158333,2.566022,-0.27424,
    0.223916,2.566022,-0.223916,0.158333,2.932112,-0.27424,0.223916,2.932112,-0.223916,
    0.081959,2.932112,-0.305875,0.158333,2.566022,-0.27424,0.081959,2.566022,-0.305875,
    0.158333,2.566022,-0.27424,0.081959,2.932112,-0.305875,0.158333,2.932112,-0.27424,
    0.0,2.932112,-0.316665,0.081959,2.566022,-0.305875,0.0,2.566022,-0.316665,
    0.081959,2.566022,-0.305875,0.0,2.932112,-0.316665,0.081959,2.932112,-0.305875,
    -0.081959,2.932112,-0.305875,0.0,2.566022,-0.316665,-0.081959,2.566022,-0.305875,
    0.0,2.566022,-0.316665,-0.081959,2.932112,-0.305875,0.0,2.932112,-0.316665,
    -0.158333,2.932112,-0.27424,-0.081959,2.566022,-0.305875,-0.158333,2.566022,-0.27424,
    -0.081959,2.566022,-0.305875,-0.158333,2.932112,-0.27424,-0.081959,2.932112,-0.305875,
    -0.223916,2.932112,-0.223916,-0.158333,2.566022,-0.27424,-0.223916,2.566022,-0.223916,
    -0.158333,2.566022,-0.27424,-0.223916,2.932112,-0.223916,-0.158333,2.932112,-0.27424,
    -0.223916,2.932112,-0.223916,-0.27424,2.566022,-0.158333,-0.27424,2.932112,-0.158333,
    -0.27424,2.566022,-0.158333,-0.223916,2.932112,-0.223916,-0.223916,2.566022,-0.223916,
    -0.27424,2.932112,-0.158333,-0.305875,2.566022,-0.081959,-0.305875,2.932112,-0.081959,
    -0.305875,2.566022,-0.081959,-0.27424,2.932112,-0.158333,-0.27424,2.566022,-0.158333,
    -0.316665,2.932112,0.0,-0.305875,2.566022,-0.081959,-0.316665,2.566022,0.0,
    -0.305875,2.566022,-0.081959,-0.316665,2.932112,0.0,-0.305875,2.932112,-0.081959,
    -0.305875,2.932112,0.081959,-0.316665,2.566022,0.0,-0.305875,2.566022,0.081959,
    -0.316665,2.566022,0.0,-0.305875,2.932112,0.081959,-0.316665,2.932112,0.0,
    -0.305875,2.932112,0.081959,-0.27424,2.566022,0.158333,-0.27424,2.932112,0.158333,
    -0.27424,2.566022,0.158333,-0.305875,2.932112,0.081959,-0.305875,2.566022,0.081959,
    -0.27424,2.932112,0.158333,-0.223916,2.566022,0.223916,-0.223916,2.932112,0.223916,
    -0.223916,2.566022,0.223916,-0.27424,2.932112,0.158333,-0.27424,2.566022,0.158333,
    -0.158333,2.932112,0.27424,-0.223916,2.566022,0.223916,-0.158333,2.566022,0.27424,
    -0.223916,2.566022,0.223916,-0.158333,2.932112,0.27424,-0.223916,2.932112,0.223916,
    -0.081959,2.932112,0.305875,-0.158333,2.566022,0.27424,-0.081959,2.566022,0.305875,
    -0.158333,2.566022,0.27424,-0.081959,2.932112,0.305875,-0.158333,2.932112,0.27424,
    0.0,2.932112,0.316665,-0.081959,2.566022,0.305875,0.0,2.566022,0.316665,
    -0.081959,2.566022,0.305875,0.0,2.932112,0.316665,-0.081959,2.932112,0.305875,
    0.081959,2.932112,0.305875,0.0,2.566022,0.316665,0.081959,2.566022,0.305875,
    0.0,2.566022,0.316665,0.081959,2.932112,0.305875,0.0,2.932112,0.316665,
    0.158333,2.932112,0.27424,0.081959,2.566022,0.305875,0.158333,2.566022,0.27424,
    0.081959,2.566022,0.305875,0.158333,2.932112,0.27424,0.081959,2.932112,0.305875,
    0.223916,2.932112,0.223916,0.158333,2.566022,0.27424,0.223916,2.566022,0.223916,
    0.158333,2.566022,0.27424,0.223916,2.932112,0.223916,0.158333,2.932112,0.27424,
    0.27424,2.566022,0.158333,0.223916,2.932112,0.223916,0.223916,2.566022,0.223916,
    0.223916,2.932112,0.223916,0.27424,2.566022,0.158333,0.27424,2.932112,0.158333,
    0.27424,2.566022,-0.158333,0.377301,2.537465,-0.377301,0.223916,2.566022,-0.223916,
    0.377301,2.537465,-0.377301,0.27424,2.566022,-0.158333,0.462098,2.537465,-0.266792,
    0.515403,2.537465,-0.138102,0.892704,2.331509,-0.515403,0.462098,2.537465,-0.266792,
    0.892704,2.331509,-0.515403,0.515403,2.537465,-0.138102,0.995682,2.331509,-0.266792,
    1.030806,2.331509,0.0,1.408107,2.00388,-0.377301,0.995682,2.331509,-0.266792,
    1.408107,2.00388,-0.377301,1.030806,2.331509,0.0,1.45778,2.00388,0.0,
    0.223916,0.128587,-0.223916,0.27424,2.566022,-0.158333,0.27424,0.128587,-0.158333,
    0.27424,2.566022,-0.158333,0.223916,0.128587,-0.223916,0.223916,2.566022,-0.223916,
    0.223916,2.566022,-0.223916,0.158333,2.566022,-0.27424,0.0,2.607711,0.0,
    0.223916,2.566022,0.223916,0.0,2.607711,0.0,0.158333,2.566022,0.27424,
    0.377301,2.537465,0.377301,0.27424,2.566022,0.158333,0.223916,2.566022,0.223916,
    0.27424,2.566022,0.158333,0.377301,2.537465,0.377301,0.462098,2.537465,0.266792,
    0.27424,0.128587,0.158333,0.223916,2.566022,0.223916,0.223916,0.128587,0.223916,
    0.223916,2.566022,0.223916,0.27424,0.128587,0.158333,0.27424,2.566022,0.158333,
    0.892704,2.331509,0.515403,0.515403,2.537465,0.138102,0.462098,2.537465,0.266792,
    0.515403,2.537465,0.138102,0.892704,2.331509,0.515403,0.995682,2.331509,0.266792,
    1.408107,2.00388,0.377301,1.030806,2.331509,0.0,0.995682,2.331509,0.266792,
    1.030806,2.331509,0.0,1.408107,2.00388,0.377301,1.45778,2.00388,0.0,
    0.223916,2.566022,-0.223916,0.266792,2.537465,-0.462098,0.158333,2.566022,-0.27424,
    0.266792,2.537465,-0.462098,0.223916,2.566022,-0.223916,0.377301,2.537465,-0.377301,
    0.158333,2.566022,-0.27424,0.223916,0.128587,-0.223916,0.158333,0.128587,-0.27424,
    0.223916,0.128587,-0.223916,0.158333,2.566022,-0.27424,0.223916,2.566022,-0.223916,
    0.158333,2.566022,-0.27424,0.081959,2.566022,-0.305875,0.0,2.607711,0.0,
    0.158333,2.566022,-0.27424,0.138102,2.537465,-0.515403,0.081959,2.566022,-0.305875,
    0.138102,2.537465,-0.515403,0.158333,2.566022,-0.27424,0.266792,2.537465,-0.462098,
    0.081959,2.566022,-0.305875,0.158333,0.128587,-0.27424,0.081959,0.128587,-0.305875,
    0.158333,0.128587,-0.27424,0.081959,2.566022,-0.305875,0.158333,2.566022,-0.27424,
    0.081959,2.566022,-0.305875,0.0,2.566022,-0.316665,0.0,2.607711,0.0,
    0.081959,2.566022,-0.305875,0.0,2.537465,-0.533585,0.0,2.566022,-0.316665,
    0.0,2.537465,-0.533585,0.081959,2.566022,-0.305875,0.138102,2.537465,-0.515403,
    0.0,2.566022,-0.316665,0.081959,0.128587,-0.305875,0.0,0.128587,-0.316665,
    0.081959,0.128587,-0.305875,0.0,2.566022,-0.316665,0.081959,2.566022,-0.305875,
    0.0,2.566022,-0.316665,-0.081959,2.566022,-0.305875,0.0,2.607711,0.0,
    -0.081959,2.566022,-0.305875,0.0,2.537465,-0.533585,-0.138102,2.537465,-0.515403,
    0.0,2.537465,-0.533585,-0.081959,2.566022,-0.305875,0.0,2.566022,-0.316665,
    -0.081959,2.566022,-0.305875,0.0,0.128587,-0.316665,-0.081959,0.128587,-0.305875,
    0.0,0.128587,-0.316665,-0.081959,2.566022,-0.305875,0.0,2.566022,-0.316665,
    0.0,2.607711,0.0,-0.081959,2.566022,-0.305875,-0.158333,2.566022,-0.27424,
    -0.158333,2.566022,-0.27424,-0.138102,2.537465,-0.515403,-0.266792,2.537465,-0.462098,
    -0.138102,2.537465,-0.515403,-0.158333,2.566022,-0.27424,-0.081959,2.566022,-0.305875,
    -0.158333,2.566022,-0.27424,-0.081959,0.128587,-0.305875,-0.158333,0.128587,-0.27424,
    -0.081959,0.128587,-0.305875,-0.158333,2.566022,-0.27424,-0.081959,2.566022,-0.305875,
    0.0,2.607711,0.0,-0.158333,2.566022,-0.27424,-0.223916,2.566022,-0.223916,
    -0.223916,2.566022,-0.223916,-0.266792,2.537465,-0.462098,-0.377301,2.537465,-0.377301,
    -0.266792,2.537465,-0.462098,-0.223916,2.566022,-0.223916,-0.158333,2.566022,-0.27424,
    -0.223916,2.566022,-0.223916,-0.158333,0.128587,-0.27424,-0.223916,0.128587,-0.223916,
    -0.158333,0.128587,-0.27424,-0.223916,2.566022,-0.223916,-0.158333,2.566022,-0.27424,
    0.0,2.607711,0.0,-0.223916,2.566022,-0.223916,-0.27424,2.566022,-0.158333,
    -0.27424,2.566022,-0.158333,-0.377301,2.537465,-0.377301,-0.462098,2.537465,-0.266792,
    -0.377301,2.537465,-0.377301,-0.27424,2.566022,-0.158333,-0.223916,2.566022,-0.223916,
    -0.27424,2.566022,-0.158333,-0.223916,0.128587,-0.223916,-0.27424,0.128587,-0.158333,
    -0.223916,0.128587,-0.223916,-0.27424,2.566022,-0.158333,-0.223916,2.566022,-0.223916,
    -0.305875,2.566022,-0.081959,-0.462098,2.537465,-0.266792,-0.515403,2.537465,-0.138102,
    -0.462098,2.537465,-0.266792,-0.305875,2.566022,-0.081959,-0.27424,2.566022,-0.158333,
    -0.305875,2.566022,-0.081959,-0.27424,0.128587,-0.158333,-0.305875,0.128587,-0.081959,
    -0.27424,0.128587,-0.158333,-0.305875,2.566022,-0.081959,-0.27424,2.566022,-0.158333,
    0.0,2.607711,0.0,-0.27424,2.566022,-0.158333,-0.305875,2.566022,-0.081959,
    0.0,2.607711,0.0,-0.305875,2.566022,-0.081959,-0.316665,2.566022,0.0,
    -0.316665,2.566022,0.0,-0.515403,2.537465,-0.138102,-0.533585,2.537465,0.0,
    -0.515403,2.537465,-0.138102,-0.316665,2.566022,0.0,-0.305875,2.566022,-0.081959,
    -0.305875,2.566022,-0.081959,-0.316665,0.128587,0.0,-0.316665,2.566022,0.0,
    -0.316665,0.128587,0.0,-0.305875,2.566022,-0.081959,-0.305875,0.128587,-0.081959,
    0.0,2.607711,0.0,-0.316665,2.566022,0.0,-0.305875,2.566022,0.081959,
    -0.515403,2.537465,0.138102,-0.316665,2.566022,0.0,-0.533585,2.537465,0.0,
    -0.316665,2.566022,0.0,-0.515403,2.537465,0.138102,-0.305875,2.566022,0.081959,
    -0.316665,2.566022,0.0,-0.305875,0.128587,0.081959,-0.305875,2.566022,0.081959,
    -0.305875,0.128587,0.081959,-0.316665,2.566022,0.0,-0.316665,0.128587,0.0,
    0.0,2.607711,0.0,-0.305875,2.566022,0.081959,-0.27424,2.566022,0.158333,
    -0.462098,2.537465,0.266792,-0.305875,2.566022,0.081959,-0.515403,2.537465,0.138102,
    -0.305875,2.566022,0.081959,-0.462098,2.537465,0.266792,-0.27424,2.566022,0.158333,
    -0.27424,2.566022,0.158333,-0.305875,0.128587,0.081959,-0.27424,0.128587,0.158333,
    -0.305875,0.128587,0.081959,-0.27424,2.566022,0.158333,-0.305875,2.566022,0.081959,
    0.0,2.607711,0.0,-0.27424,2.566022,0.158333,-0.223916,2.566022,0.223916,
    -0.377301,2.537465,0.377301,-0.27424,2.566022,0.158333,-0.462098,2.537465,0.266792,
    -0.27424,2.566022,0.158333,-0.377301,2.537465,0.377301,-0.223916,2.566022,0.223916,
    -0.223916,2.566022,0.223916,-0.27424,0.128587,0.158333,-0.223916,0.128587,0.223916,
    -0.27424,0.128587,0.158333,-0.223916,2.566022,0.223916,-0.27424,2.566022,0.158333,
    0.0,2.607711,0.0,-0.223916,2.566022,0.223916,-0.158333,2.566022,0.27424,
    -0.266792,2.537465,0.462098,-0.223916,2.566022,0.223916,-0.377301,2.537465,0.377301,
    -0.223916,2.566022,0.223916,-0.266792,2.537465,0.462098,-0.158333,2.566022,0.27424,
    -0.158333,2.566022,0.27424,-0.223916,0.128587,0.223916,-0.158333,0.128587,0.27424,
    -0.223916,0.128587,0.223916,-0.158333,2.566022,0.27424,-0.223916,2.566022,0.223916,
    0.0,2.607711,0.0,-0.158333,2.566022,0.27424,-0.081959,2.566022,0.305875,
    -0.138102,2.537465,0.515403,-0.158333,2.566022,0.27424,-0.266792,2.537465,0.462098,
    -0.158333,2.566022,0.27424,-0.138102,2.537465,0.515403,-0.081959,2.566022,0.305875,
    -0.081959,2.566022,0.305875,-0.158333,0.128587,0.27424,-0.081959,0.128587,0.305875,
    -0.158333,0.128587,0.27424,-0.081959,2.566022,0.305875,-0.158333,2.566022,0.27424,
    0.0,2.566022,0.316665,0.0,2.607711,0.0,-0.081959,2.566022,0.305875,
    0.0,2.537465,0.533585,-0.081959,2.566022,0.305875,-0.138102,2.537465,0.515403,
    -0.081959,2.566022,0.305875,0.0,2.537465,0.533585,0.0,2.566022,0.316665,
    0.0,2.566022,0.316665,-0.081959,0.128587,0.305875,0.0,0.128587,0.316665,
    -0.081959,0.128587,0.305875,0.0,2.566022,0.316665,-0.081959,2.566022,0.305875,
    0.0,2.537465,0.533585,0.081959,2.566022,0.305875,0.0,2.566022,0.316665,
    0.081959,2.566022,0.305875,0.0,2.537465,0.533585,0.138102,2.537465,0.515403,
    0.081959,2.566022,0.305875,0.0,0.128587,0.316665,0.081959,0.128587,0.305875,
    0.0,0.128587,0.316665,0.081959,2.566022,0.305875,0.0,2.566022,0.316665,
    0.081959,2.566022,0.305875,0.0,2.607711,0.0,0.0,2.566022,0.316665,
    0.158333,2.566022,0.27424,0.0,2.607711,0.0,0.081959,2.566022,0.305875,
    0.138102,2.537465,0.515403,0.158333,2.566022,0.27424,0.081959,2.566022,0.305875,
    0.158333,2.566022,0.27424,0.138102,2.537465,0.515403,0.266792,2.537465,0.462098,
    0.158333,2.566022,0.27424,0.081959,0.128587,0.305875,0.158333,0.128587,0.27424,
    0.081959,0.128587,0.305875,0.158333,2.566022,0.27424,0.081959,2.566022,0.305875,
    0.266792,2.537465,0.462098,0.223916,2.566022,0.223916,0.158333,2.566022,0.27424,
    0.223916,2.566022,0.223916,0.266792,2.537465,0.462098,0.377301,2.537465,0.377301,
    0.223916,2.566022,0.223916,0.158333,0.128587,0.27424,0.223916,0.128587,0.223916,
    0.158333,0.128587,0.27424,0.223916,2.566022,0.223916,0.158333,2.566022,0.27424,
    0.462098,2.537465,-0.266792,0.72889,2.331509,-0.72889,0.377301,2.537465,-0.377301,
    0.72889,2.331509,-0.72889,0.462098,2.537465,-0.266792,0.892704,2.331509,-0.515403,
    0.995682,2.331509,-0.266792,1.262475,2.00388,-0.72889,0.892704,2.331509,-0.515403,
    1.262475,2.00388,-0.72889,0.995682,2.331509,-0.266792,1.408107,2.00388,-0.377301,
    1.724572,1.576906,-0.462098,1.45778,2.00388,0.0,1.785409,1.576906,0.0,
    1.45778,2.00388,0.0,1.724572,1.576906,-0.462098,1.408107,2.00388,-0.377301,
    0.72889,2.331509,0.72889,0.462098,2.537465,0.266792,0.377301,2.537465,0.377301,
    0.462098,2.537465,0.266792,0.72889,2.331509,0.72889,0.892704,2.331509,0.515403,
    1.262475,2.00388,0.72889,0.995682,2.331509,0.266792,0.892704,2.331509,0.515403,
    0.995682,2.331509,0.266792,1.262475,2.00388,0.72889,1.408107,2.00388,0.377301,
    1.785409,1.576906,0.0,1.408107,2.00388,0.377301,1.724572,1.576906,0.462098,
    1.408107,2.00388,0.377301,1.785409,1.576906,0.0,1.45778,2.00388,0.0,
    0.377301,2.537465,-0.377301,0.515403,2.331509,-0.892704,0.266792,2.537465,-0.462098,
    0.515403,2.331509,-0.892704,0.377301,2.537465,-0.377301,0.72889,2.331509,-0.72889,
    0.266792,2.537465,-0.462098,0.266792,2.331509,-0.995682,0.138102,2.537465,-0.515403,
    0.266792,2.331509,-0.995682,0.266792,2.537465,-0.462098,0.515403,2.331509,-0.892704,
    0.138102,2.537465,-0.515403,0.0,2.331509,-1.030806,0.0,2.537465,-0.533585,
    0.0,2.331509,-1.030806,0.138102,2.537465,-0.515403,0.266792,2.331509,-0.995682,
    -0.138102,2.537465,-0.515403,0.0,2.331509,-1.030806,-0.266792,2.331509,-0.995682,
    0.0,2.331509,-1.030806,-0.138102,2.537465,-0.515403,0.0,2.537465,-0.533585,
    -0.266792,2.537465,-0.462098,-0.266792,2.331509,-0.995682,-0.515403,2.331509,-0.892704,
    -0.266792,2.331509,-0.995682,-0.266792,2.537465,-0.462098,-0.138102,2.537465,-0.515403,
    -0.377301,2.537465,-0.377301,-0.515403,2.331509,-0.892704,-0.72889,2.331509,-0.72889,
    -0.515403,2.331509,-0.892704,-0.377301,2.537465,-0.377301,-0.266792,2.537465,-0.462098,
    -0.462098,2.537465,-0.266792,-0.72889,2.331509,-0.72889,-0.892704,2.331509,-0.515403,
    -0.72889,2.331509,-0.72889,-0.462098,2.537465,-0.266792,-0.377301,2.537465,-0.377301,
    -0.515403,2.537465,-0.138102,-0.892704,2.331509,-0.515403,-0.995682,2.331509,-0.266792,
    -0.892704,2.331509,-0.515403,-0.515403,2.537465,-0.138102,-0.462098,2.537465,-0.266792,
    -0.533585,2.537465,0.0,-0.995682,2.331509,-0.266792,-1.030806,2.331509,0.0,
    -0.995682,2.331509,-0.266792,-0.533585,2.537465,0.0,-0.515403,2.537465,-0.138102,
    -0.995682,2.331509,0.266792,-0.533585,2.537465,0.0,-1.030806,2.331509,0.0,
    -0.533585,2.537465,0.0,-0.995682,2.331509,0.266792,-0.515403,2.537465,0.138102,
    -0.892704,2.331509,0.515403,-0.515403,2.537465,0.138102,-0.995682,2.331509,0.266792,
    -0.515403,2.537465,0.138102,-0.892704,2.331509,0.515403,-0.462098,2.537465,0.266792,
    -0.72889,2.331509,0.72889,-0.462098,2.537465,0.266792,-0.892704,2.331509,0.515403,
    -0.462098,2.537465,0.266792,-0.72889,2.331509,0.72889,-0.377301,2.537465,0.377301,
    -0.515403,2.331509,0.892704,-0.377301,2.537465,0.377301,-0.72889,2.331509,0.72889,
    -0.377301,2.537465,0.377301,-0.515403,2.331509,0.892704,-0.266792,2.537465,0.462098,
    -0.266792,2.331509,0.995682,-0.266792,2.537465,0.462098,-0.515403,2.331509,0.892704,
    -0.266792,2.537465,0.462098,-0.266792,2.331509,0.995682,-0.138102,2.537465,0.515403,
    0.0,2.331509,1.030806,-0.138102,2.537465,0.515403,-0.266792,2.331509,0.995682,
    -0.138102,2.537465,0.515403,0.0,2.331509,1.030806,0.0,2.537465,0.533585,
    0.266792,2.331509,0.995682,0.0,2.537465,0.533585,0.0,2.331509,1.030806,
    0.0,2.537465,0.533585,0.266792,2.331509,0.995682,0.138102,2.537465,0.515403,
    0.266792,2.331509,0.995682,0.266792,2.537465,0.462098,0.138102,2.537465,0.515403,
    0.266792,2.537465,0.462098,0.266792,2.331509,0.995682,0.515403,2.331509,0.892704,
    0.515403,2.331509,0.892704,0.377301,2.537465,0.377301,0.266792,2.537465,0.462098,
    0.377301,2.537465,0.377301,0.515403,2.331509,0.892704,0.72889,2.331509,0.72889,
    0.892704,2.331509,-0.515403,1.030806,2.00388,-1.030806,0.72889,2.331509,-0.72889,
    1.030806,2.00388,-1.030806,0.892704,2.331509,-0.515403,1.262475,2.00388,-0.72889,
    1.724572,1.576906,-0.462098,1.262475,2.00388,-0.72889,1.408107,2.00388,-0.377301,
    1.262475,2.00388,-0.72889,1.724572,1.576906,-0.462098,1.546209,1.576906,-0.892704,
    1.92351,1.079685,-0.515403,1.785409,1.576906,0.0,1.991365,1.079685,0.0,
    1.785409,1.576906,0.0,1.92351,1.079685,-0.515403,1.724572,1.576906,-0.462098,
    1.030806,2.00388,1.030806,0.892704,2.331509,0.515403,0.72889,2.331509,0.72889,
    0.892704,2.331509,0.515403,1.030806,2.00388,1.030806,1.262475,2.00388,0.72889,
    1.724572,1.576906,0.462098,1.262475,2.00388,0.72889,1.546209,1.576906,0.892704,
    1.262475,2.00388,0.72889,1.724572,1.576906,0.462098,1.408107,2.00388,0.377301,
    1.991365,1.079685,0.0,1.724572,1.576906,0.462098,1.92351,1.079685,0.515403,
    1.724572,1.576906,0.462098,1.991365,1.079685,0.0,1.785409,1.576906,0.0,
    0.72889,2.331509,-0.72889,0.72889,2.00388,-1.262475,0.515403,2.331509,-0.892704,
    0.72889,2.00388,-1.262475,0.72889,2.331509,-0.72889,1.030806,2.00388,-1.030806,
    0.515403,2.331509,-0.892704,0.377301,2.00388,-1.408107,0.266792,2.331509,-0.995682,
    0.377301,2.00388,-1.408107,0.515403,2.331509,-0.892704,0.72889,2.00388,-1.262475,
    0.266792,2.331509,-0.995682,0.0,2.00388,-1.45778,0.0,2.331509,-1.030806,
    0.0,2.00388,-1.45778,0.266792,2.331509,-0.995682,0.377301,2.00388,-1.408107,
    -0.266792,2.331509,-0.995682,0.0,2.00388,-1.45778,-0.377301,2.00388,-1.408107,
    0.0,2.00388,-1.45778,-0.266792,2.331509,-0.995682,0.0,2.331509,-1.030806,
    -0.515403,2.331509,-0.892704,-0.377301,2.00388,-1.408107,-0.72889,2.00388,-1.262475,
    -0.377301,2.00388,-1.408107,-0.515403,2.331509,-0.892704,-0.266792,2.331509,-0.995682,
    -0.72889,2.331509,-0.72889,-0.72889,2.00388,-1.262475,-1.030806,2.00388,-1.030806,
    -0.72889,2.00388,-1.262475,-0.72889,2.331509,-0.72889,-0.515403,2.331509,-0.892704,
    -0.892704,2.331509,-0.515403,-1.030806,2.00388,-1.030806,-1.262475,2.00388,-0.72889,
    -1.030806,2.00388,-1.030806,-0.892704,2.331509,-0.515403,-0.72889,2.331509,-0.72889,
    -0.995682,2.331509,-0.266792,-1.262475,2.00388,-0.72889,-1.408107,2.00388,-0.377301,
    -1.262475,2.00388,-0.72889,-0.995682,2.331509,-0.266792,-0.892704,2.331509,-0.515403,
    -1.030806,2.331509,0.0,-1.408107,2.00388,-0.377301,-1.45778,2.00388,0.0,
    -1.408107,2.00388,-0.377301,-1.030806,2.331509,0.0,-0.995682,2.331509,-0.266792,
    -1.408107,2.00388,0.377301,-1.030806,2.331509,0.0,-1.45778,2.00388,0.0,
    -1.030806,2.331509,0.0,-1.408107,2.00388,0.377301,-0.995682,2.331509,0.266792,
    -1.262475,2.00388,0.72889,-0.995682,2.331509,0.266792,-1.408107,2.00388,0.377301,
    -0.995682,2.331509,0.266792,-1.262475,2.00388,0.72889,-0.892704,2.331509,0.515403,
    -1.030806,2.00388,1.030806,-0.892704,2.331509,0.515403,-1.262475,2.00388,0.72889,
    -0.892704,2.331509,0.515403,-1.030806,2.00388,1.030806,-0.72889,2.331509,0.72889,
    -0.72889,2.00388,1.262475,-0.72889,2.331509,0.72889,-1.030806,2.00388,1.030806,
    -0.72889,2.331509,0.72889,-0.72889,2.00388,1.262475,-0.515403,2.331509,0.892704,
    -0.377301,2.00388,1.408107,-0.515403,2.331509,0.892704,-0.72889,2.00388,1.262475,
    -0.515403,2.331509,0.892704,-0.377301,2.00388,1.408107,-0.266792,2.331509,0.995682,
    0.0,2.00388,1.45778,-0.266792,2.331509,0.995682,-0.377301,2.00388,1.408107,
    -0.266792,2.331509,0.995682,0.0,2.00388,1.45778,0.0,2.331509,1.030806,
    0.377301,2.00388,1.408107,0.0,2.331509,1.030806,0.0,2.00388,1.45778,
    0.0,2.331509,1.030806,0.377301,2.00388,1.408107,0.266792,2.331509,0.995682,
    0.377301,2.00388,1.408107,0.515403,2.331509,0.892704,0.266792,2.331509,0.995682,
    0.515403,2.331509,0.892704,0.377301,2.00388,1.408107,0.72889,2.00388,1.262475,
    0.72889,2.00388,1.262475,0.72889,2.331509,0.72889,0.515403,2.331509,0.892704,
    0.72889,2.331509,0.72889,0.72889,2.00388,1.262475,1.030806,2.00388,1.030806,
    1.546209,1.576906,-0.892704,1.030806,2.00388,-1.030806,1.262475,2.00388,-0.72889,
    1.030806,2.00388,-1.030806,1.546209,1.576906,-0.892704,1.262475,1.576906,-1.262475,
    1.92351,1.079685,-0.515403,1.546209,1.576906,-0.892704,1.724572,1.576906,-0.462098,
    1.546209,1.576906,-0.892704,1.92351,1.079685,-0.515403,1.724572,1.079685,-0.995682,
    1.991365,0.5461,-0.533585,1.991365,1.079685,0.0,2.061612,0.5461,0.0,
    1.991365,1.079685,0.0,1.991365,0.5461,-0.533585,1.92351,1.079685,-0.515403,
    1.546209,1.576906,0.892704,1.030806,2.00388,1.030806,1.262475,1.576906,1.262475,
    1.030806,2.00388,1.030806,1.546209,1.576906,0.892704,1.262475,2.00388,0.72889,
    1.92351,1.079685,0.515403,1.546209,1.576906,0.892704,1.724572,1.079685,0.995682,
    1.546209,1.576906,0.892704,1.92351,1.079685,0.515403,1.724572,1.576906,0.462098,
    2.061612,0.5461,0.0,1.92351,1.079685,0.515403,1.991365,0.5461,0.533585,
    1.92351,1.079685,0.515403,2.061612,0.5461,0.0,1.991365,1.079685,0.0,
    0.72889,2.00388,-1.262475,1.262475,1.576906,-1.262475,0.892704,1.576906,-1.546209,
    1.262475,1.576906,-1.262475,0.72889,2.00388,-1.262475,1.030806,2.00388,-1.030806,
    0.377301,2.00388,-1.408107,0.892704,1.576906,-1.546209,0.462098,1.576906,-1.724572,
    0.892704,1.576906,-1.546209,0.377301,2.00388,-1.408107,0.72889,2.00388,-1.262475,
    0.0,2.00388,-1.45778,0.462098,1.576906,-1.724572,0.0,1.576906,-1.785409,
    0.462098,1.576906,-1.724572,0.0,2.00388,-1.45778,0.377301,2.00388,-1.408107,
    -0.377301,2.00388,-1.408107,0.0,1.576906,-1.785409,-0.462098,1.576906,-1.724572,
    0.0,1.576906,-1.785409,-0.377301,2.00388,-1.408107,0.0,2.00388,-1.45778,
    -0.72889,2.00388,-1.262475,-0.462098,1.576906,-1.724572,-0.892704,1.576906,-1.546209,
    -0.462098,1.576906,-1.724572,-0.72889,2.00388,-1.262475,-0.377301,2.00388,-1.408107,
    -1.030806,2.00388,-1.030806,-0.892704,1.576906,-1.546209,-1.262475,1.576906,-1.262475,
    -0.892704,1.576906,-1.546209,-1.030806,2.00388,-1.030806,-0.72889,2.00388,-1.262475,
    -1.030806,2.00388,-1.030806,-1.546209,1.576906,-0.892704,-1.262475,2.00388,-0.72889,
    -1.546209,1.576906,-0.892704,-1.030806,2.00388,-1.030806,-1.262475,1.576906,-1.262475,
    -1.262475,2.00388,-0.72889,-1.724572,1.576906,-0.462098,-1.408107,2.00388,-0.377301,
    -1.724572,1.576906,-0.462098,-1.262475,2.00388,-0.72889,-1.546209,1.576906,-0.892704,
    -1.408107,2.00388,-0.377301,-1.785409,1.576906,0.0,-1.45778,2.00388,0.0,
    -1.785409,1.576906,0.0,-1.408107,2.00388,-0.377301,-1.724572,1.576906,-0.462098,
    -1.408107,2.00388,0.377301,-1.785409,1.576906,0.0,-1.724572,1.576906,0.462098,
    -1.785409,1.576906,0.0,-1.408107,2.00388,0.377301,-1.45778,2.00388,0.0,
    -1.262475,2.00388,0.72889,-1.724572,1.576906,0.462098,-1.546209,1.576906,0.892704,
    -1.724572,1.576906,0.462098,-1.262475,2.00388,0.72889,-1.408107,2.00388,0.377301,
    -1.030806,2.00388,1.030806,-1.546209,1.576906,0.892704,-1.262475,1.576906,1.262475,
    -1.546209,1.576906,0.892704,-1.030806,2.00388,1.030806,-1.262475,2.00388,0.72889,
    -0.72889,2.00388,1.262475,-1.262475,1.576906,1.262475,-0.892704,1.576906,1.546209,
    -1.262475,1.576906,1.262475,-0.72889,2.00388,1.262475,-1.030806,2.00388,1.030806,
    -0.377301,2.00388,1.408107,-0.892704,1.576906,1.546209,-0.462098,1.576906,1.724572,
    -0.892704,1.576906,1.546209,-0.377301,2.00388,1.408107,-0.72889,2.00388,1.262475,
    0.0,2.00388,1.45778,-0.462098,1.576906,1.724572,0.0,1.576906,1.785409,
    -0.462098,1.576906,1.724572,0.0,2.00388,1.45778,-0.377301,2.00388,1.408107,
    0.377301,2.00388,1.408107,0.0,1.576906,1.785409,0.462098,1.576906,1.724572,
    0.0,1.576906,1.785409,0.377301,2.00388,1.408107,0.0,2.00388,1.45778,
    0.72889,2.00388,1.262475,0.462098,1.576906,1.724572,0.892704,1.576906,1.546209,
    0.462098,1.576906,1.724572,0.72889,2.00388,1.262475,0.377301,2.00388,1.408107,
    1.030806,2.00388,1.030806,0.892704,1.576906,1.546209,1.262475,1.576906,1.262475,
    0.892704,1.576906,1.546209,1.030806,2.00388,1.030806,0.72889,2.00388,1.262475,
    1.724572,1.079685,-0.995682,1.262475,1.576906,-1.262475,1.546209,1.576906,-0.892704,
    1.262475,1.576906,-1.262475,1.724572,1.079685,-0.995682,1.408107,1.079685,-1.408107,
    1.991365,0.5461,-0.533585,1.724572,1.079685,-0.995682,1.92351,1.079685,-0.515403,
    1.724572,1.079685,-0.995682,1.991365,0.5461,-0.533585,1.785409,0.5461,-1.030806,
    1.724572,1.079685,0.995682,1.262475,1.576906,1.262475,1.408107,1.079685,1.408107,
    1.262475,1.576906,1.262475,1.724572,1.079685,0.995682,1.546209,1.576906,0.892704,
    1.991365,0.5461,0.533585,1.724572,1.079685,0.995682,1.785409,0.5461,1.030806,
    1.724572,1.079685,0.995682,1.991365,0.5461,0.533585,1.92351,1.079685,0.515403,
    0.892704,1.576906,-1.546209,1.408107,1.079685,-1.408107,0.995682,1.079685,-1.724572,
    1.408107,1.079685,-1.408107,0.892704,1.576906,-1.546209,1.262475,1.576906,-1.262475,
    0.462098,1.576906,-1.724572,0.995682,1.079685,-1.724572,0.515403,1.079685,-1.92351,
    0.995682,1.079685,-1.724572,0.462098,1.576906,-1.724572,0.892704,1.576906,-1.546209,
    0.0,1.576906,-1.785409,0.515403,1.079685,-1.92351,0.0,1.079685,-1.991365,
    0.515403,1.079685,-1.92351,0.0,1.576906,-1.785409,0.462098,1.576906,-1.724572,
    -0.462098,1.576906,-1.724572,0.0,1.079685,-1.991365,-0.515403,1.079685,-1.92351,
    0.0,1.079685,-1.991365,-0.462098,1.576906,-1.724572,0.0,1.576906,-1.785409,
    -0.892704,1.576906,-1.546209,-0.515403,1.079685,-1.92351,-0.995682,1.079685,-1.724572,
    -0.515403,1.079685,-1.92351,-0.892704,1.576906,-1.546209,-0.462098,1.576906,-1.724572,
    -1.262475,1.576906,-1.262475,-0.995682,1.079685,-1.724572,-1.408107,1.079685,-1.408107,
    -0.995682,1.079685,-1.724572,-1.262475,1.576906,-1.262475,-0.892704,1.576906,-1.546209,
    -1.262475,1.576906,-1.262475,-1.724572,1.079685,-0.995682,-1.546209,1.576906,-0.892704,
    -1.724572,1.079685,-0.995682,-1.262475,1.576906,-1.262475,-1.408107,1.079685,-1.408107,
    -1.546209,1.576906,-0.892704,-1.92351,1.079685,-0.515403,-1.724572,1.576906,-0.462098,
    -1.92351,1.079685,-0.515403,-1.546209,1.576906,-0.892704,-1.724572,1.079685,-0.995682,
    -1.724572,1.576906,-0.462098,-1.991365,1.079685,0.0,-1.785409,1.576906,0.0,
    -1.991365,1.079685,0.0,-1.724572,1.576906,-0.462098,-1.92351,1.079685,-0.515403,
    -1.724572,1.576906,0.462098,-1.991365,1.079685,0.0,-1.92351,1.079685,0.515403,
    -1.991365,1.079685,0.0,-1.724572,1.576906,0.462098,-1.785409,1.576906,0.0,
    -1.546209,1.576906,0.892704,-1.92351,1.079685,0.515403,-1.724572,1.079685,0.995682,
    -1.92351,1.079685,0.515403,-1.546209,1.576906,0.892704,-1.724572,1.576906,0.462098,
    -1.262475,1.576906,1.262475,-1.724572,1.079685,0.995682,-1.408107,1.079685,1.408107,
    -1.724572,1.079685,0.995682,-1.262475,1.576906,1.262475,-1.546209,1.576906,0.892704,
    -0.892704,1.576906,1.546209,-1.408107,1.079685,1.408107,-0.995682,1.079685,1.724572,
    -1.408107,1.079685,1.408107,-0.892704,1.576906,1.546209,-1.262475,1.576906,1.262475,
    -0.462098,1.576906,1.724572,-0.995682,1.079685,1.724572,-0.515403,1.079685,1.92351,
    -0.995682,1.079685,1.724572,-0.462098,1.576906,1.724572,-0.892704,1.576906,1.546209,
    0.0,1.576906,1.785409,-0.515403,1.079685,1.92351,0.0,1.079685,1.991365,
    -0.515403,1.079685,1.92351,0.0,1.576906,1.785409,-0.462098,1.576906,1.724572,
    0.462098,1.576906,1.724572,0.0,1.079685,1.991365,0.515403,1.079685,1.92351,
    0.0,1.079685,1.991365,0.462098,1.576906,1.724572,0.0,1.576906,1.785409,
    0.892704,1.576906,1.546209,0.515403,1.079685,1.92351,0.995682,1.079685,1.724572,
    0.515403,1.079685,1.92351,0.892704,1.576906,1.546209,0.462098,1.576906,1.724572,
    1.262475,1.576906,1.262475,0.995682,1.079685,1.724572,1.408107,1.079685,1.408107,
    0.995682,1.079685,1.724572,1.262475,1.576906,1.262475,0.892704,1.576906,1.546209,
    1.785409,0.5461,-1.030806,1.408107,1.079685,-1.408107,1.724572,1.079685,-0.995682,
    1.408107,1.079685,-1.408107,1.785409,0.5461,-1.030806,1.45778,0.5461,-1.45778,
    1.785409,0.5461,1.030806,1.408107,1.079685,1.408107,1.45778,0.5461,1.45778,
    1.408107,1.079685,1.408107,1.785409,0.5461,1.030806,1.724572,1.079685,0.995682,
    0.995682,1.079685,-1.724572,1.45778,0.5461,-1.45778,1.030806,0.5461,-1.785409,
    1.45778,0.5461,-1.45778,0.995682,1.079685,-1.724572,1.408107,1.079685,-1.408107,
    0.515403,1.079685,-1.92351,1.030806,0.5461,-1.785409,0.533585,0.5461,-1.991365,
    1.030806,0.5461,-1.785409,0.515403,1.079685,-1.92351,0.995682,1.079685,-1.724572,
    0.0,1.079685,-1.991365,0.533585,0.5461,-1.991365,0.0,0.5461,-2.061612,
    0.533585,0.5461,-1.991365,0.0,1.079685,-1.991365,0.515403,1.079685,-1.92351,
    -0.515403,1.079685,-1.92351,0.0,0.5461,-2.061612,-0.533585,0.5461,-1.991365,
    0.0,0.5461,-2.061612,-0.515403,1.079685,-1.92351,0.0,1.079685,-1.991365,
    -0.995682,1.079685,-1.724572,-0.533585,0.5461,-1.991365,-1.030806,0.5461,-1.785409,
    -0.533585,0.5461,-1.991365,-0.995682,1.079685,-1.724572,-0.515403,1.079685,-1.92351,
    -1.408107,1.079685,-1.408107,-1.030806,0.5461,-1.785409,-1.45778,0.5461,-1.45778,
    -1.030806,0.5461,-1.785409,-1.408107,1.079685,-1.408107,-0.995682,1.079685,-1.724572,
    -1.408107,1.079685,-1.408107,-1.785409,0.5461,-1.030806,-1.724572,1.079685,-0.995682,
    -1.785409,0.5461,-1.030806,-1.408107,1.079685,-1.408107,-1.45778,0.5461,-1.45778,
    -1.724572,1.079685,-0.995682,-1.991365,0.5461,-0.533585,-1.92351,1.079685,-0.515403,
    -1.991365,0.5461,-0.533585,-1.724572,1.079685,-0.995682,-1.785409,0.5461,-1.030806,
    -1.92351,1.079685,-0.515403,-2.061612,0.5461,0.0,-1.991365,1.079685,0.0,
    -2.061612,0.5461,0.0,-1.92351,1.079685,-0.515403,-1.991365,0.5461,-0.533585,
    -1.92351,1.079685,0.515403,-2.061612,0.5461,0.0,-1.991365,0.5461,0.533585,
    -2.061612,0.5461,0.0,-1.92351,1.079685,0.515403,-1.991365,1.079685,0.0,
    -1.724572,1.079685,0.995682,-1.991365,0.5461,0.533585,-1.785409,0.5461,1.030806,
    -1.991365,0.5461,0.533585,-1.724572,1.079685,0.995682,-1.92351,1.079685,0.515403,
    -1.408107,1.079685,1.408107,-1.785409,0.5461,1.030806,-1.45778,0.5461,1.45778,
    -1.785409,0.5461,1.030806,-1.408107,1.079685,1.408107,-1.724572,1.079685,0.995682,
    -0.995682,1.079685,1.724572,-1.45778,0.5461,1.45778,-1.030806,0.5461,1.785409,
    -1.45778,0.5461,1.45778,-0.995682,1.079685,1.724572,-1.408107,1.079685,1.408107,
    -0.515403,1.079685,1.92351,-1.030806,0.5461,1.785409,-0.533585,0.5461,1.991365,
    -1.030806,0.5461,1.785409,-0.515403,1.079685,1.92351,-0.995682,1.079685,1.724572,
    0.0,1.079685,1.991365,-0.533585,0.5461,1.991365,0.0,0.5461,2.061612,
    -0.533585,0.5461,1.991365,0.0,1.079685,1.991365,-0.515403,1.079685,1.92351,
    0.515403,1.079685,1.92351,0.0,0.5461,2.061612,0.533585,0.5461,1.991365,
    0.0,0.5461,2.061612,0.515403,1.079685,1.92351,0.0,1.079685,1.991365,
    0.995682,1.079685,1.724572,0.533585,0.5461,1.991365,1.030806,0.5461,1.785409,
    0.533585,0.5461,1.991365,0.995682,1.079685,1.724572,0.515403,1.079685,1.92351,
    1.408107,1.079685,1.408107,1.030806,0.5461,1.785409,1.45778,0.5461,1.45778,
    1.030806,0.5461,1.785409,1.408107,1.079685,1.408107,0.995682,1.079685,1.724572,
    -2.287693,0.0,-1.3208,-2.452667,0.0,0.0,-2.55159,0.0,-0.683696,
    -2.452667,0.0,0.0,-2.287693,0.0,-1.3208,-2.369095,0.0,-0.634797,
    -2.369095,0.0,-0.634797,-2.287693,0.0,-1.3208,-2.124072,0.0,-1.226334,
    -2.124072,0.0,-1.226334,-2.287693,0.0,-1.3208,-1.867893,0.0,-1.867893,
    -2.124072,0.0,-1.226334,-1.867893,0.0,-1.867893,-1.734298,0.0,-1.734298,
    -1.734298,0.0,-1.734298,-1.867893,0.0,-1.867893,-1.3208,0.0,-2.287693,
    -1.734298,0.0,-1.734298,-1.3208,0.0,-2.287693,-1.226334,0.0,-2.124072,
    -1.226334,0.0,-2.124072,-1.3208,0.0,-2.287693,-0.683696,0.0,-2.55159,
    -1.226334,0.0,-2.124072,-0.683696,0.0,-2.55159,-0.634797,0.0,-2.369095,
    -0.634797,0.0,-2.369095,-0.683696,0.0,-2.55159,0.0,0.0,-2.6416,
    -0.634797,0.0,-2.369095,0.0,0.0,-2.6416,0.0,0.0,-2.452667,
    0.0,0.0,-2.452667,0.0,0.0,-2.6416,0.683696,0.0,-2.55159,
    0.0,0.0,-2.452667,0.683696,0.0,-2.55159,0.634797,0.0,-2.369095,
    0.634797,0.0,-2.369095,0.683696,0.0,-2.55159,1.226334,0.0,-2.124072,
    1.226334,0.0,-2.124072,0.683696,0.0,-2.55159,1.3208,0.0,-2.287693,
    1.226334,0.0,-2.124072,1.3208,0.0,-2.287693,1.734298,0.0,-1.734298,
    1.734298,0.0,-1.734298,1.3208,0.0,-2.287693,1.867893,0.0,-1.867893,
    1.734298,0.0,-1.734298,1.867893,0.0,-1.867893,2.124072,0.0,-1.226334,
    2.124072,0.0,-1.226334,1.867893,0.0,-1.867893,2.287693,0.0,-1.3208,
    2.124072,0.0,-1.226334,2.287693,0.0,-1.3208,2.369095,0.0,-0.634797,
    2.369095,0.0,-0.634797,2.287693,0.0,-1.3208,2.55159,0.0,-0.683696,
    2.369095,0.0,-0.634797,2.55159,0.0,-0.683696,2.452667,0.0,0.0,
    2.452667,0.0,0.0,2.55159,0.0,-0.683696,2.55159,0.0,0.683696,
    2.55159,0.0,0.683696,2.55159,0.0,-0.683696,2.6416,0.0,0.0,
    -2.55159,0.0,-0.683696,-2.55159,0.0,0.683696,-2.6416,0.0,0.0,
    -2.55159,0.0,0.683696,-2.55159,0.0,-0.683696,-2.287693,0.0,1.3208,
    -2.287693,0.0,1.3208,-2.55159,0.0,-0.683696,-2.452667,0.0,0.0,
    -2.287693,0.0,1.3208,-2.452667,0.0,0.0,-2.369095,0.0,0.634797,
    -2.287693,0.0,1.3208,-2.369095,0.0,0.634797,-2.124072,0.0,1.226334,
    -2.287693,0.0,1.3208,-2.124072,0.0,1.226334,-1.867893,0.0,1.867893,
    -1.867893,0.0,1.867893,-2.124072,0.0,1.226334,-1.734298,0.0,1.734298,
    -1.867893,0.0,1.867893,-1.734298,0.0,1.734298,-1.3208,0.0,2.287693,
    -1.3208,0.0,2.287693,-1.734298,0.0,1.734298,-1.226334,0.0,2.124072,
    -1.3208,0.0,2.287693,-1.226334,0.0,2.124072,-0.683696,0.0,2.55159,
    -0.683696,0.0,2.55159,-1.226334,0.0,2.124072,-0.634797,0.0,2.369095,
    -0.683696,0.0,2.55159,-0.634797,0.0,2.369095,0.0,0.0,2.6416,
    0.0,0.0,2.6416,-0.634797,0.0,2.369095,0.0,0.0,2.452667,
    0.0,0.0,2.6416,0.0,0.0,2.452667,0.683696,0.0,2.55159,
    0.683696,0.0,2.55159,0.0,0.0,2.452667,0.634797,0.0,2.369095,
    0.683696,0.0,2.55159,0.634797,0.0,2.369095,1.226334,0.0,2.124072,
    0.683696,0.0,2.55159,1.226334,0.0,2.124072,1.3208,0.0,2.287693,
    1.3208,0.0,2.287693,1.226334,0.0,2.124072,1.734298,0.0,1.734298,
    1.3208,0.0,2.287693,1.734298,0.0,1.734298,1.867893,0.0,1.867893,
    1.867893,0.0,1.867893,1.734298,0.0,1.734298,2.124072,0.0,1.226334,
    1.867893,0.0,1.867893,2.124072,0.0,1.226334,2.287693,0.0,1.3208,
    2.287693,0.0,1.3208,2.124072,0.0,1.226334,2.369095,0.0,0.634797,
    2.287693,0.0,1.3208,2.369095,0.0,0.634797,2.55159,0.0,0.683696,
    2.55159,0.0,0.683696,2.369095,0.0,0.634797,2.452667,0.0,0.0,
    -2.55159,0.5461,0.683696,-2.55159,0.5461,-0.683696,-2.6416,0.5461,0.0,
    -2.55159,0.5461,-0.683696,-2.55159,0.5461,0.683696,-2.287693,0.5461,1.3208,
    -2.55159,0.5461,-0.683696,-2.287693,0.5461,1.3208,-2.287693,0.5461,-1.3208,
    -2.287693,0.5461,-1.3208,-2.287693,0.5461,1.3208,-1.867893,0.5461,1.867893,
    -2.287693,0.5461,-1.3208,-1.867893,0.5461,1.867893,-2.061612,0.5461,0.0,
    -2.061612,0.5461,0.0,-1.867893,0.5461,1.867893,-1.991365,0.5461,0.533585,
    -1.991365,0.5461,0.533585,-1.867893,0.5461,1.867893,-1.785409,0.5461,1.030806,
    -1.785409,0.5461,1.030806,-1.867893,0.5461,1.867893,-1.3208,0.5461,2.287693,
    -1.785409,0.5461,1.030806,-1.3208,0.5461,2.287693,-1.45778,0.5461,1.45778,
    -1.45778,0.5461,1.45778,-1.3208,0.5461,2.287693,-1.030806,0.5461,1.785409,
    -1.030806,0.5461,1.785409,-1.3208,0.5461,2.287693,-0.683696,0.5461,2.55159,
    -1.030806,0.5461,1.785409,-0.683696,0.5461,2.55159,-0.533585,0.5461,1.991365,
    -0.533585,0.5461,1.991365,-0.683696,0.5461,2.55159,0.0,0.5461,2.6416,
    -0.533585,0.5461,1.991365,0.0,0.5461,2.6416,0.0,0.5461,2.061612,
    0.0,0.5461,2.061612,0.0,0.5461,2.6416,0.683696,0.5461,2.55159,
    0.0,0.5461,2.061612,0.683696,0.5461,2.55159,0.533585,0.5461,1.991365,
    0.533585,0.5461,1.991365,0.683696,0.5461,2.55159,1.030806,0.5461,1.785409,
    1.030806,0.5461,1.785409,0.683696,0.5461,2.55159,1.3208,0.5461,2.287693,
    1.030806,0.5461,1.785409,1.3208,0.5461,2.287693,1.45778,0.5461,1.45778,
    1.45778,0.5461,1.45778,1.3208,0.5461,2.287693,1.867893,0.5461,1.867893,
    1.45778,0.5461,1.45778,1.867893,0.5461,1.867893,1.785409,0.5461,1.030806,
    1.785409,0.5461,1.030806,1.867893,0.5461,1.867893,1.991365,0.5461,0.533585,
    1.991365,0.5461,0.533585,1.867893,0.5461,1.867893,2.287693,0.5461,1.3208,
    1.991365,0.5461,0.533585,2.287693,0.5461,1.3208,2.061612,0.5461,0.0,
    -2.061612,0.5461,0.0,-1.867893,0.5461,-1.867893,-2.287693,0.5461,-1.3208,
    -1.867893,0.5461,-1.867893,-2.061612,0.5461,0.0,-1.991365,0.5461,-0.533585,
    -1.867893,0.5461,-1.867893,-1.991365,0.5461,-0.533585,-1.785409,0.5461,-1.030806,
    -1.867893,0.5461,-1.867893,-1.785409,0.5461,-1.030806,-1.3208,0.5461,-2.287693,
    -1.3208,0.5461,-2.287693,-1.785409,0.5461,-1.030806,-1.45778,0.5461,-1.45778,
    -1.3208,0.5461,-2.287693,-1.45778,0.5461,-1.45778,-1.030806,0.5461,-1.785409,
    -1.3208,0.5461,-2.287693,-1.030806,0.5461,-1.785409,-0.683696,0.5461,-2.55159,
    -0.683696,0.5461,-2.55159,-1.030806,0.5461,-1.785409,-0.533585,0.5461,-1.991365,
    -0.683696,0.5461,-2.55159,-0.533585,0.5461,-1.991365,0.0,0.5461,-2.6416,
    0.0,0.5461,-2.6416,-0.533585,0.5461,-1.991365,0.0,0.5461,-2.061612,
    0.0,0.5461,-2.6416,0.0,0.5461,-2.061612,0.683696,0.5461,-2.55159,
    0.683696,0.5461,-2.55159,0.0,0.5461,-2.061612,0.533585,0.5461,-1.991365,
    0.683696,0.5461,-2.55159,0.533585,0.5461,-1.991365,1.030806,0.5461,-1.785409,
    0.683696,0.5461,-2.55159,1.030806,0.5461,-1.785409,1.3208,0.5461,-2.287693,
    1.3208,0.5461,-2.287693,1.030806,0.5461,-1.785409,1.45778,0.5461,-1.45778,
    1.3208,0.5461,-2.287693,1.45778,0.5461,-1.45778,1.867893,0.5461,-1.867893,
    1.867893,0.5461,-1.867893,1.45778,0.5461,-1.45778,1.785409,0.5461,-1.030806,
    1.867893,0.5461,-1.867893,1.785409,0.5461,-1.030806,1.991365,0.5461,-0.533585,
    1.867893,0.5461,-1.867893,1.991365,0.5461,-0.533585,2.287693,0.5461,-1.3208,
    2.287693,0.5461,-1.3208,1.991365,0.5461,-0.533585,2.061612,0.5461,0.0,
    2.287693,0.5461,-1.3208,2.061612,0.5461,0.0,2.287693,0.5461,1.3208,
    2.287693,0.5461,-1.3208,2.287693,0.5461,1.3208,2.55159,0.5461,0.683696,
    2.287693,0.5461,-1.3208,2.55159,0.5461,0.683696,2.55159,0.5461,-0.683696,
    2.55159,0.5461,-0.683696,2.55159,0.5461,0.683696,2.6416,0.5461,0.0,
    2.287693,0.0,-1.3208,2.55159,0.5461,-0.683696,2.55159,0.0,-0.683696,
    2.55159,0.5461,-0.683696,2.287693,0.0,-1.3208,2.287693,0.5461,-1.3208,
    2.55159,0.0,-0.683696,2.6416,0.5461,0.0,2.6416,0.0,0.0,
    2.6416,0.5461,0.0,2.55159,0.0,-0.683696,2.55159,0.5461,-0.683696,
    2.6416,0.0,0.0,2.55159,0.5461,0.683696,2.55159,0.0,0.683696,
    2.55159,0.5461,0.683696,2.6416,0.0,0.0,2.6416,0.5461,0.0,
    2.55159,0.0,0.683696,2.287693,0.5461,1.3208,2.287693,0.0,1.3208,
    2.287693,0.5461,1.3208,2.55159,0.0,0.683696,2.55159,0.5461,0.683696,
    2.287693,0.0,1.3208,1.867893,0.5461,1.867893,1.867893,0.0,1.867893,
    1.867893,0.5461,1.867893,2.287693,0.0,1.3208,2.287693,0.5461,1.3208,
    1.867893,0.5461,1.867893,1.3208,0.0,2.287693,1.867893,0.0,1.867893,
    1.3208,0.0,2.287693,1.867893,0.5461,1.867893,1.3208,0.5461,2.287693,
    1.3208,0.5461,2.287693,0.683696,0.0,2.55159,1.3208,0.0,2.287693,
    0.683696,0.0,2.55159,1.3208,0.5461,2.287693,0.683696,0.5461,2.55159,
    0.683696,0.5461,2.55159,0.0,0.0,2.6416,0.683696,0.0,2.55159,
    0.0,0.0,2.6416,0.683696,0.5461,2.55159,0.0,0.5461,2.6416,
    0.0,0.5461,2.6416,-0.683696,0.0,2.55159,0.0,0.0,2.6416,
    -0.683696,0.0,2.55159,0.0,0.5461,2.6416,-0.683696,0.5461,2.55159,
    -0.683696,0.5461,2.55159,-1.3208,0.0,2.287693,-0.683696,0.0,2.55159,
    -1.3208,0.0,2.287693,-0.683696,0.5461,2.55159,-1.3208,0.5461,2.287693,
    -1.3208,0.5461,2.287693,-1.867893,0.0,1.867893,-1.3208,0.0,2.287693,
    -1.867893,0.0,1.867893,-1.3208,0.5461,2.287693,-1.867893,0.5461,1.867893,
    -2.287693,0.5461,1.3208,-1.867893,0.0,1.867893,-1.867893,0.5461,1.867893,
    -1.867893,0.0,1.867893,-2.287693,0.5461,1.3208,-2.287693,0.0,1.3208,
    -2.55159,0.5461,0.683696,-2.287693,0.0,1.3208,-2.287693,0.5461,1.3208,
    -2.287693,0.0,1.3208,-2.55159,0.5461,0.683696,-2.55159,0.0,0.683696,
    -2.6416,0.5461,0.0,-2.55159,0.0,0.683696,-2.55159,0.5461,0.683696,
    -2.55159,0.0,0.683696,-2.6416,0.5461,0.0,-2.6416,0.0,0.0,
    -2.55159,0.5461,-0.683696,-2.6416,0.0,0.0,-2.6416,0.5461,0.0,
    -2.6416,0.0,0.0,-2.55159,0.5461,-0.683696,-2.55159,0.0,-0.683696,
    -2.287693,0.5461,-1.3208,-2.55159,0.0,-0.683696,-2.55159,0.5461,-0.683696,
    -2.55159,0.0,-0.683696,-2.287693,0.5461,-1.3208,-2.287693,0.0,-1.3208,
    -1.867893,0.5461,-1.867893,-2.287693,0.0,-1.3208,-2.287693,0.5461,-1.3208,
    -2.287693,0.0,-1.3208,-1.867893,0.5461,-1.867893,-1.867893,0.0,-1.867893,
    -1.867893,0.5461,-1.867893,-1.3208,0.0,-2.287693,-1.867893,0.0,-1.867893,
    -1.3208,0.0,-2.287693,-1.867893,0.5461,-1.867893,-1.3208,0.5461,-2.287693,
    -1.3208,0.5461,-2.287693,-0.683696,0.0,-2.55159,-1.3208,0.0,-2.287693,
    -0.683696,0.0,-2.55159,-1.3208,0.5461,-2.287693,-0.683696,0.5461,-2.55159,
    -0.683696,0.5461,-2.55159,0.0,0.0,-2.6416,-0.683696,0.0,-2.55159,
    0.0,0.0,-2.6416,-0.683696,0.5461,-2.55159,0.0,0.5461,-2.6416,
    0.0,0.5461,-2.6416,0.683696,0.0,-2.55159,0.0,0.0,-2.6416,
    0.683696,0.0,-2.55159,0.0,0.5461,-2.6416,0.683696,0.5461,-2.55159,
    0.683696,0.5461,-2.55159,1.3208,0.0,-2.287693,0.683696,0.0,-2.55159,
    1.3208,0.0,-2.287693,0.683696,0.5461,-2.55159,1.3208,0.5461,-2.287693,
    1.3208,0.5461,-2.287693,1.867893,0.0,-1.867893,1.3208,0.0,-2.287693,
    1.867893,0.0,-1.867893,1.3208,0.5461,-2.287693,1.867893,0.5461,-1.867893,
    1.867893,0.0,-1.867893,2.287693,0.5461,-1.3208,2.287693,0.0,-1.3208,
    2.287693,0.5461,-1.3208,1.867893,0.0,-1.867893,1.867893,0.5461,-1.867893,
]

var vn_crane: [GLfloat] = [
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.5,0.0,-0.866,0.7071,0.0,-0.7071,0.5,0.0,-0.866,
    0.7071,0.0,-0.7071,0.5,0.0,-0.866,0.7071,0.0,-0.7071,
    0.7071,0.0,-0.7071,0.866,0.0,-0.5,0.866,0.0,-0.5,
    0.866,0.0,-0.5,0.7071,0.0,-0.7071,0.7071,0.0,-0.7071,
    0.866,0.0,-0.5,0.9659,0.0,-0.2588,0.9659,0.0,-0.2588,
    0.9659,0.0,-0.2588,0.866,0.0,-0.5,0.866,0.0,-0.5,
    0.9659,0.0,-0.2588,1.0,0.0,0.0,1.0,0.0,0.0,
    1.0,0.0,0.0,0.9659,0.0,-0.2588,0.9659,0.0,-0.2588,
    1.0,0.0,0.0,0.9659,0.0,0.2588,0.9659,0.0,0.2588,
    0.9659,0.0,0.2588,1.0,0.0,0.0,1.0,0.0,0.0,
    0.9659,0.0,0.2588,0.866,0.0,0.5,0.866,0.0,0.5,
    0.866,0.0,0.5,0.9659,0.0,0.2588,0.9659,0.0,0.2588,
    0.866,0.0,0.5,0.7071,0.0,0.7071,0.7071,0.0,0.7071,
    0.7071,0.0,0.7071,0.866,0.0,0.5,0.866,0.0,0.5,
    0.7071,0.0,0.7071,0.5,0.0,0.866,0.7071,0.0,0.7071,
    0.5,0.0,0.866,0.7071,0.0,0.7071,0.5,0.0,0.866,
    0.5,0.0,0.866,0.2588,0.0,0.9659,0.5,0.0,0.866,
    0.2588,0.0,0.9659,0.5,0.0,0.866,0.2588,0.0,0.9659,
    0.2588,0.0,0.9659,0.0,0.0,1.0,0.2588,0.0,0.9659,
    0.0,0.0,1.0,0.2588,0.0,0.9659,0.0,0.0,1.0,
    0.0,0.0,1.0,-0.2588,0.0,0.9659,0.0,0.0,1.0,
    -0.2588,0.0,0.9659,0.0,0.0,1.0,-0.2588,0.0,0.9659,
    -0.2588,0.0,0.9659,-0.5,0.0,0.866,-0.2588,0.0,0.9659,
    -0.5,0.0,0.866,-0.2588,0.0,0.9659,-0.5,0.0,0.866,
    -0.5,0.0,0.866,-0.7071,0.0,0.7071,-0.5,0.0,0.866,
    -0.7071,0.0,0.7071,-0.5,0.0,0.866,-0.7071,0.0,0.7071,
    -0.866,0.0,0.5,-0.7071,0.0,0.7071,-0.7071,0.0,0.7071,
    -0.7071,0.0,0.7071,-0.866,0.0,0.5,-0.866,0.0,0.5,
    -0.9659,0.0,0.2588,-0.866,0.0,0.5,-0.866,0.0,0.5,
    -0.866,0.0,0.5,-0.9659,0.0,0.2588,-0.9659,0.0,0.2588,
    -1.0,0.0,0.0,-0.9659,0.0,0.2588,-0.9659,0.0,0.2588,
    -0.9659,0.0,0.2588,-1.0,0.0,0.0,-1.0,0.0,0.0,
    -0.9659,0.0,-0.2588,-1.0,0.0,0.0,-1.0,0.0,0.0,
    -1.0,0.0,0.0,-0.9659,0.0,-0.2588,-0.9659,0.0,-0.2588,
    -0.866,0.0,-0.5,-0.9659,0.0,-0.2588,-0.9659,0.0,-0.2588,
    -0.9659,0.0,-0.2588,-0.866,0.0,-0.5,-0.866,0.0,-0.5,
    -0.7071,0.0,-0.7071,-0.866,0.0,-0.5,-0.866,0.0,-0.5,
    -0.866,0.0,-0.5,-0.7071,0.0,-0.7071,-0.7071,0.0,-0.7071,
    -0.7071,0.0,-0.7071,-0.5,0.0,-0.866,-0.7071,0.0,-0.7071,
    -0.5,0.0,-0.866,-0.7071,0.0,-0.7071,-0.5,0.0,-0.866,
    -0.5,0.0,-0.866,-0.2588,0.0,-0.9659,-0.5,0.0,-0.866,
    -0.2588,0.0,-0.9659,-0.5,0.0,-0.866,-0.2588,0.0,-0.9659,
    -0.2588,0.0,-0.9659,0.0,0.0,-1.0,-0.2588,0.0,-0.9659,
    0.0,0.0,-1.0,-0.2588,0.0,-0.9659,0.0,0.0,-1.0,
    0.0,0.0,-1.0,0.2588,0.0,-0.9659,0.0,0.0,-1.0,
    0.2588,0.0,-0.9659,0.0,0.0,-1.0,0.2588,0.0,-0.9659,
    0.2588,0.0,-0.9659,0.5,0.0,-0.866,0.2588,0.0,-0.9659,
    0.5,0.0,-0.866,0.2588,0.0,-0.9659,0.5,0.0,-0.866,
    0.5,0.0,-0.866,0.7071,0.0,-0.7071,0.5,0.0,-0.866,
    0.7071,0.0,-0.7071,0.5,0.0,-0.866,0.7071,0.0,-0.7071,
    0.7071,0.0,-0.7071,0.866,0.0,-0.5,0.866,0.0,-0.5,
    0.866,0.0,-0.5,0.7071,0.0,-0.7071,0.7071,0.0,-0.7071,
    0.866,0.0,-0.5,0.9659,0.0,-0.2588,0.9659,0.0,-0.2588,
    0.9659,0.0,-0.2588,0.866,0.0,-0.5,0.866,0.0,-0.5,
    0.9659,0.0,-0.2588,1.0,0.0,0.0,1.0,0.0,0.0,
    1.0,0.0,0.0,0.9659,0.0,-0.2588,0.9659,0.0,-0.2588,
    1.0,0.0,0.0,0.9659,0.0,0.2588,0.9659,0.0,0.2588,
    0.9659,0.0,0.2588,1.0,0.0,0.0,1.0,0.0,0.0,
    0.9659,0.0,0.2588,0.866,0.0,0.5,0.866,0.0,0.5,
    0.866,0.0,0.5,0.9659,0.0,0.2588,0.9659,0.0,0.2588,
    0.866,0.0,0.5,0.7071,0.0,0.7071,0.7071,0.0,0.7071,
    0.7071,0.0,0.7071,0.866,0.0,0.5,0.866,0.0,0.5,
    0.7071,0.0,0.7071,0.5,0.0,0.866,0.7071,0.0,0.7071,
    0.5,0.0,0.866,0.7071,0.0,0.7071,0.5,0.0,0.866,
    0.5,0.0,0.866,0.2588,0.0,0.9659,0.5,0.0,0.866,
    0.2588,0.0,0.9659,0.5,0.0,0.866,0.2588,0.0,0.9659,
    0.2588,0.0,0.9659,0.0,0.0,1.0,0.2588,0.0,0.9659,
    0.0,0.0,1.0,0.2588,0.0,0.9659,0.0,0.0,1.0,
    0.0,0.0,1.0,-0.2588,0.0,0.9659,0.0,0.0,1.0,
    -0.2588,0.0,0.9659,0.0,0.0,1.0,-0.2588,0.0,0.9659,
    -0.2588,0.0,0.9659,-0.5,0.0,0.866,-0.2588,0.0,0.9659,
    -0.5,0.0,0.866,-0.2588,0.0,0.9659,-0.5,0.0,0.866,
    -0.5,0.0,0.866,-0.7071,0.0,0.7071,-0.5,0.0,0.866,
    -0.7071,0.0,0.7071,-0.5,0.0,0.866,-0.7071,0.0,0.7071,
    -0.866,0.0,0.5,-0.7071,0.0,0.7071,-0.7071,0.0,0.7071,
    -0.7071,0.0,0.7071,-0.866,0.0,0.5,-0.866,0.0,0.5,
    -0.9659,0.0,0.2588,-0.866,0.0,0.5,-0.866,0.0,0.5,
    -0.866,0.0,0.5,-0.9659,0.0,0.2588,-0.9659,0.0,0.2588,
    -1.0,0.0,0.0,-0.9659,0.0,0.2588,-0.9659,0.0,0.2588,
    -0.9659,0.0,0.2588,-1.0,0.0,0.0,-1.0,0.0,0.0,
    -0.9659,0.0,-0.2588,-1.0,0.0,0.0,-1.0,0.0,0.0,
    -1.0,0.0,0.0,-0.9659,0.0,-0.2588,-0.9659,0.0,-0.2588,
    -0.866,0.0,-0.5,-0.9659,0.0,-0.2588,-0.9659,0.0,-0.2588,
    -0.9659,0.0,-0.2588,-0.866,0.0,-0.5,-0.866,0.0,-0.5,
    -0.7071,0.0,-0.7071,-0.866,0.0,-0.5,-0.866,0.0,-0.5,
    -0.866,0.0,-0.5,-0.7071,0.0,-0.7071,-0.7071,0.0,-0.7071,
    -0.7071,0.0,-0.7071,-0.5,0.0,-0.866,-0.7071,0.0,-0.7071,
    -0.5,0.0,-0.866,-0.7071,0.0,-0.7071,-0.5,0.0,-0.866,
    -0.5,0.0,-0.866,-0.2588,0.0,-0.9659,-0.5,0.0,-0.866,
    -0.2588,0.0,-0.9659,-0.5,0.0,-0.866,-0.2588,0.0,-0.9659,
    -0.2588,0.0,-0.9659,0.0,0.0,-1.0,-0.2588,0.0,-0.9659,
    0.0,0.0,-1.0,-0.2588,0.0,-0.9659,0.0,0.0,-1.0,
    0.0,0.0,-1.0,0.2588,0.0,-0.9659,0.0,0.0,-1.0,
    0.2588,0.0,-0.9659,0.0,0.0,-1.0,0.2588,0.0,-0.9659,
    0.2588,0.0,-0.9659,0.5,0.0,-0.866,0.2588,0.0,-0.9659,
    0.5,0.0,-0.866,0.2588,0.0,-0.9659,0.5,0.0,-0.866,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.1305,0.9914,0.0,0.1261,0.9914,-0.0338,0.0,1.0,0.0,
    0.1305,0.9914,0.0,0.0,1.0,0.0,0.1261,0.9914,0.0338,
    0.9659,0.0,-0.2588,1.0,0.0,0.0,1.0,0.0,0.0,
    1.0,0.0,0.0,0.9659,0.0,-0.2588,0.9659,0.0,-0.2588,
    0.1305,0.9914,0.0,0.2597,0.9632,-0.0696,0.1261,0.9914,-0.0338,
    0.2597,0.9632,-0.0696,0.1305,0.9914,0.0,0.2689,0.9632,0.0,
    1.0,0.0,0.0,0.9659,0.0,-0.2588,1.0,0.0,0.0,
    0.9659,0.0,-0.2588,1.0,0.0,0.0,0.9659,0.0,-0.2588,
    0.1261,0.9914,-0.0338,0.113,0.9914,-0.0652,0.0,1.0,0.0,
    0.1261,0.9914,0.0338,0.0,1.0,0.0,0.113,0.9914,0.0652,
    1.0,0.0,0.0,0.9659,0.0,0.2588,0.9659,0.0,0.2588,
    0.9659,0.0,0.2588,1.0,0.0,0.0,1.0,0.0,0.0,
    0.2597,0.9632,0.0696,0.1305,0.9914,0.0,0.1261,0.9914,0.0338,
    0.1305,0.9914,0.0,0.2597,0.9632,0.0696,0.2689,0.9632,0.0,
    0.9659,0.0,0.2588,1.0,0.0,0.0,0.9659,0.0,0.2588,
    1.0,0.0,0.0,0.9659,0.0,0.2588,1.0,0.0,0.0,
    0.9659,0.0,-0.2588,0.866,0.0,-0.5,0.9659,0.0,-0.2588,
    0.866,0.0,-0.5,0.9659,0.0,-0.2588,0.866,0.0,-0.5,
    0.1261,0.9914,-0.0338,0.2329,0.9632,-0.1344,0.113,0.9914,-0.0652,
    0.2329,0.9632,-0.1344,0.1261,0.9914,-0.0338,0.2597,0.9632,-0.0696,
    0.2689,0.9632,0.0,0.4907,0.8613,-0.1315,0.2597,0.9632,-0.0696,
    0.4907,0.8613,-0.1315,0.2689,0.9632,0.0,0.508,0.8613,0.0,
    0.866,0.0,-0.5,0.9659,0.0,-0.2588,0.9659,0.0,-0.2588,
    0.9659,0.0,-0.2588,0.866,0.0,-0.5,0.866,0.0,-0.5,
    0.113,0.9914,-0.0652,0.0923,0.9914,-0.0923,0.0,1.0,0.0,
    0.113,0.9914,0.0652,0.0,1.0,0.0,0.0923,0.9914,0.0923,
    0.9659,0.0,0.2588,0.866,0.0,0.5,0.866,0.0,0.5,
    0.866,0.0,0.5,0.9659,0.0,0.2588,0.9659,0.0,0.2588,
    0.2329,0.9632,0.1344,0.1261,0.9914,0.0338,0.113,0.9914,0.0652,
    0.1261,0.9914,0.0338,0.2329,0.9632,0.1344,0.2597,0.9632,0.0696,
    0.866,0.0,0.5,0.9659,0.0,0.2588,0.866,0.0,0.5,
    0.9659,0.0,0.2588,0.866,0.0,0.5,0.9659,0.0,0.2588,
    0.4907,0.8613,0.1315,0.2689,0.9632,0.0,0.2597,0.9632,0.0696,
    0.2689,0.9632,0.0,0.4907,0.8613,0.1315,0.508,0.8613,0.0,
    0.866,0.0,-0.5,0.7071,0.0,-0.7071,0.866,0.0,-0.5,
    0.7071,0.0,-0.7071,0.866,0.0,-0.5,0.7071,0.0,-0.7071,
    0.5,0.0,-0.866,0.7071,0.0,-0.7071,0.5,0.0,-0.866,
    0.7071,0.0,-0.7071,0.5,0.0,-0.866,0.7071,0.0,-0.7071,
    0.2588,0.0,-0.9659,0.5,0.0,-0.866,0.2588,0.0,-0.9659,
    0.5,0.0,-0.866,0.2588,0.0,-0.9659,0.5,0.0,-0.866,
    0.0,0.0,-1.0,0.2588,0.0,-0.9659,0.0,0.0,-1.0,
    0.2588,0.0,-0.9659,0.0,0.0,-1.0,0.2588,0.0,-0.9659,
    -0.2588,0.0,-0.9659,0.0,0.0,-1.0,-0.2588,0.0,-0.9659,
    0.0,0.0,-1.0,-0.2588,0.0,-0.9659,0.0,0.0,-1.0,
    -0.5,0.0,-0.866,-0.2588,0.0,-0.9659,-0.5,0.0,-0.866,
    -0.2588,0.0,-0.9659,-0.5,0.0,-0.866,-0.2588,0.0,-0.9659,
    -0.7071,0.0,-0.7071,-0.5,0.0,-0.866,-0.7071,0.0,-0.7071,
    -0.5,0.0,-0.866,-0.7071,0.0,-0.7071,-0.5,0.0,-0.866,
    -0.7071,0.0,-0.7071,-0.866,0.0,-0.5,-0.866,0.0,-0.5,
    -0.866,0.0,-0.5,-0.7071,0.0,-0.7071,-0.7071,0.0,-0.7071,
    -0.866,0.0,-0.5,-0.9659,0.0,-0.2588,-0.9659,0.0,-0.2588,
    -0.9659,0.0,-0.2588,-0.866,0.0,-0.5,-0.866,0.0,-0.5,
    -1.0,0.0,0.0,-0.9659,0.0,-0.2588,-1.0,0.0,0.0,
    -0.9659,0.0,-0.2588,-1.0,0.0,0.0,-0.9659,0.0,-0.2588,
    -0.9659,0.0,0.2588,-1.0,0.0,0.0,-0.9659,0.0,0.2588,
    -1.0,0.0,0.0,-0.9659,0.0,0.2588,-1.0,0.0,0.0,
    -0.9659,0.0,0.2588,-0.866,0.0,0.5,-0.866,0.0,0.5,
    -0.866,0.0,0.5,-0.9659,0.0,0.2588,-0.9659,0.0,0.2588,
    -0.866,0.0,0.5,-0.7071,0.0,0.7071,-0.7071,0.0,0.7071,
    -0.7071,0.0,0.7071,-0.866,0.0,0.5,-0.866,0.0,0.5,
    -0.5,0.0,0.866,-0.7071,0.0,0.7071,-0.5,0.0,0.866,
    -0.7071,0.0,0.7071,-0.5,0.0,0.866,-0.7071,0.0,0.7071,
    -0.2588,0.0,0.9659,-0.5,0.0,0.866,-0.2588,0.0,0.9659,
    -0.5,0.0,0.866,-0.2588,0.0,0.9659,-0.5,0.0,0.866,
    0.0,0.0,1.0,-0.2588,0.0,0.9659,0.0,0.0,1.0,
    -0.2588,0.0,0.9659,0.0,0.0,1.0,-0.2588,0.0,0.9659,
    0.2588,0.0,0.9659,0.0,0.0,1.0,0.2588,0.0,0.9659,
    0.0,0.0,1.0,0.2588,0.0,0.9659,0.0,0.0,1.0,
    0.5,0.0,0.866,0.2588,0.0,0.9659,0.5,0.0,0.866,
    0.2588,0.0,0.9659,0.5,0.0,0.866,0.2588,0.0,0.9659,
    0.7071,0.0,0.7071,0.5,0.0,0.866,0.7071,0.0,0.7071,
    0.5,0.0,0.866,0.7071,0.0,0.7071,0.5,0.0,0.866,
    0.866,0.0,0.5,0.7071,0.0,0.7071,0.7071,0.0,0.7071,
    0.7071,0.0,0.7071,0.866,0.0,0.5,0.866,0.0,0.5,
    0.113,0.9914,-0.0652,0.1901,0.9632,-0.1901,0.0923,0.9914,-0.0923,
    0.1901,0.9632,-0.1901,0.113,0.9914,-0.0652,0.2329,0.9632,-0.1344,
    0.2597,0.9632,-0.0696,0.44,0.8613,-0.254,0.2329,0.9632,-0.1344,
    0.44,0.8613,-0.254,0.2597,0.9632,-0.0696,0.4907,0.8613,-0.1315,
    0.508,0.8613,0.0,0.6882,0.7017,-0.1844,0.4907,0.8613,-0.1315,
    0.6882,0.7017,-0.1844,0.508,0.8613,0.0,0.7125,0.7017,0.0,
    0.7071,0.0,-0.7071,0.866,0.0,-0.5,0.866,0.0,-0.5,
    0.866,0.0,-0.5,0.7071,0.0,-0.7071,0.7071,0.0,-0.7071,
    0.0923,0.9914,-0.0923,0.0652,0.9914,-0.113,0.0,1.0,0.0,
    0.0923,0.9914,0.0923,0.0,1.0,0.0,0.0652,0.9914,0.113,
    0.1901,0.9632,0.1901,0.113,0.9914,0.0652,0.0923,0.9914,0.0923,
    0.113,0.9914,0.0652,0.1901,0.9632,0.1901,0.2329,0.9632,0.1344,
    0.866,0.0,0.5,0.7071,0.0,0.7071,0.7071,0.0,0.7071,
    0.7071,0.0,0.7071,0.866,0.0,0.5,0.866,0.0,0.5,
    0.44,0.8613,0.254,0.2597,0.9632,0.0696,0.2329,0.9632,0.1344,
    0.2597,0.9632,0.0696,0.44,0.8613,0.254,0.4907,0.8613,0.1315,
    0.6882,0.7017,0.1844,0.508,0.8613,0.0,0.4907,0.8613,0.1315,
    0.508,0.8613,0.0,0.6882,0.7017,0.1844,0.7125,0.7017,0.0,
    0.0923,0.9914,-0.0923,0.1344,0.9632,-0.2329,0.0652,0.9914,-0.113,
    0.1344,0.9632,-0.2329,0.0923,0.9914,-0.0923,0.1901,0.9632,-0.1901,
    0.5,0.0,-0.866,0.7071,0.0,-0.7071,0.5,0.0,-0.866,
    0.7071,0.0,-0.7071,0.5,0.0,-0.866,0.7071,0.0,-0.7071,
    0.0652,0.9914,-0.113,0.0338,0.9914,-0.1261,0.0,1.0,0.0,
    0.0652,0.9914,-0.113,0.0696,0.9632,-0.2597,0.0338,0.9914,-0.1261,
    0.0696,0.9632,-0.2597,0.0652,0.9914,-0.113,0.1344,0.9632,-0.2329,
    0.2588,0.0,-0.9659,0.5,0.0,-0.866,0.2588,0.0,-0.9659,
    0.5,0.0,-0.866,0.2588,0.0,-0.9659,0.5,0.0,-0.866,
    0.0338,0.9914,-0.1261,0.0,0.9914,-0.1305,0.0,1.0,0.0,
    0.0338,0.9914,-0.1261,0.0,0.9632,-0.2689,0.0,0.9914,-0.1305,
    0.0,0.9632,-0.2689,0.0338,0.9914,-0.1261,0.0696,0.9632,-0.2597,
    0.0,0.0,-1.0,0.2588,0.0,-0.9659,0.0,0.0,-1.0,
    0.2588,0.0,-0.9659,0.0,0.0,-1.0,0.2588,0.0,-0.9659,
    0.0,0.9914,-0.1305,-0.0338,0.9914,-0.1261,0.0,1.0,0.0,
    -0.0338,0.9914,-0.1261,0.0,0.9632,-0.2689,-0.0696,0.9632,-0.2597,
    0.0,0.9632,-0.2689,-0.0338,0.9914,-0.1261,0.0,0.9914,-0.1305,
    -0.2588,0.0,-0.9659,0.0,0.0,-1.0,-0.2588,0.0,-0.9659,
    0.0,0.0,-1.0,-0.2588,0.0,-0.9659,0.0,0.0,-1.0,
    0.0,1.0,0.0,-0.0338,0.9914,-0.1261,-0.0652,0.9914,-0.113,
    -0.0652,0.9914,-0.113,-0.0696,0.9632,-0.2597,-0.1344,0.9632,-0.2329,
    -0.0696,0.9632,-0.2597,-0.0652,0.9914,-0.113,-0.0338,0.9914,-0.1261,
    -0.5,0.0,-0.866,-0.2588,0.0,-0.9659,-0.5,0.0,-0.866,
    -0.2588,0.0,-0.9659,-0.5,0.0,-0.866,-0.2588,0.0,-0.9659,
    0.0,1.0,0.0,-0.0652,0.9914,-0.113,-0.0923,0.9914,-0.0923,
    -0.0923,0.9914,-0.0923,-0.1344,0.9632,-0.2329,-0.1901,0.9632,-0.1901,
    -0.1344,0.9632,-0.2329,-0.0923,0.9914,-0.0923,-0.0652,0.9914,-0.113,
    -0.7071,0.0,-0.7071,-0.5,0.0,-0.866,-0.7071,0.0,-0.7071,
    -0.5,0.0,-0.866,-0.7071,0.0,-0.7071,-0.5,0.0,-0.866,
    0.0,1.0,0.0,-0.0923,0.9914,-0.0923,-0.113,0.9914,-0.0652,
    -0.113,0.9914,-0.0652,-0.1901,0.9632,-0.1901,-0.2329,0.9632,-0.1344,
    -0.1901,0.9632,-0.1901,-0.113,0.9914,-0.0652,-0.0923,0.9914,-0.0923,
    -0.866,0.0,-0.5,-0.7071,0.0,-0.7071,-0.866,0.0,-0.5,
    -0.7071,0.0,-0.7071,-0.866,0.0,-0.5,-0.7071,0.0,-0.7071,
    -0.1261,0.9914,-0.0338,-0.2329,0.9632,-0.1344,-0.2597,0.9632,-0.0696,
    -0.2329,0.9632,-0.1344,-0.1261,0.9914,-0.0338,-0.113,0.9914,-0.0652,
    -0.9659,0.0,-0.2588,-0.866,0.0,-0.5,-0.9659,0.0,-0.2588,
    -0.866,0.0,-0.5,-0.9659,0.0,-0.2588,-0.866,0.0,-0.5,
    0.0,1.0,0.0,-0.113,0.9914,-0.0652,-0.1261,0.9914,-0.0338,
    0.0,1.0,0.0,-0.1261,0.9914,-0.0338,-0.1305,0.9914,0.0,
    -0.1305,0.9914,0.0,-0.2597,0.9632,-0.0696,-0.2689,0.9632,0.0,
    -0.2597,0.9632,-0.0696,-0.1305,0.9914,0.0,-0.1261,0.9914,-0.0338,
    -0.9659,0.0,-0.2588,-1.0,0.0,0.0,-1.0,0.0,0.0,
    -1.0,0.0,0.0,-0.9659,0.0,-0.2588,-0.9659,0.0,-0.2588,
    0.0,1.0,0.0,-0.1305,0.9914,0.0,-0.1261,0.9914,0.0338,
    -0.2597,0.9632,0.0696,-0.1305,0.9914,0.0,-0.2689,0.9632,0.0,
    -0.1305,0.9914,0.0,-0.2597,0.9632,0.0696,-0.1261,0.9914,0.0338,
    -1.0,0.0,0.0,-0.9659,0.0,0.2588,-0.9659,0.0,0.2588,
    -0.9659,0.0,0.2588,-1.0,0.0,0.0,-1.0,0.0,0.0,
    0.0,1.0,0.0,-0.1261,0.9914,0.0338,-0.113,0.9914,0.0652,
    -0.2329,0.9632,0.1344,-0.1261,0.9914,0.0338,-0.2597,0.9632,0.0696,
    -0.1261,0.9914,0.0338,-0.2329,0.9632,0.1344,-0.113,0.9914,0.0652,
    -0.866,0.0,0.5,-0.9659,0.0,0.2588,-0.866,0.0,0.5,
    -0.9659,0.0,0.2588,-0.866,0.0,0.5,-0.9659,0.0,0.2588,
    0.0,1.0,0.0,-0.113,0.9914,0.0652,-0.0923,0.9914,0.0923,
    -0.1901,0.9632,0.1901,-0.113,0.9914,0.0652,-0.2329,0.9632,0.1344,
    -0.113,0.9914,0.0652,-0.1901,0.9632,0.1901,-0.0923,0.9914,0.0923,
    -0.7071,0.0,0.7071,-0.866,0.0,0.5,-0.7071,0.0,0.7071,
    -0.866,0.0,0.5,-0.7071,0.0,0.7071,-0.866,0.0,0.5,
    0.0,1.0,0.0,-0.0923,0.9914,0.0923,-0.0652,0.9914,0.113,
    -0.1344,0.9632,0.2329,-0.0923,0.9914,0.0923,-0.1901,0.9632,0.1901,
    -0.0923,0.9914,0.0923,-0.1344,0.9632,0.2329,-0.0652,0.9914,0.113,
    -0.5,0.0,0.866,-0.7071,0.0,0.7071,-0.5,0.0,0.866,
    -0.7071,0.0,0.7071,-0.5,0.0,0.866,-0.7071,0.0,0.7071,
    0.0,1.0,0.0,-0.0652,0.9914,0.113,-0.0338,0.9914,0.1261,
    -0.0696,0.9632,0.2597,-0.0652,0.9914,0.113,-0.1344,0.9632,0.2329,
    -0.0652,0.9914,0.113,-0.0696,0.9632,0.2597,-0.0338,0.9914,0.1261,
    -0.2588,0.0,0.9659,-0.5,0.0,0.866,-0.2588,0.0,0.9659,
    -0.5,0.0,0.866,-0.2588,0.0,0.9659,-0.5,0.0,0.866,
    0.0,0.9914,0.1305,0.0,1.0,0.0,-0.0338,0.9914,0.1261,
    0.0,0.9632,0.2689,-0.0338,0.9914,0.1261,-0.0696,0.9632,0.2597,
    -0.0338,0.9914,0.1261,0.0,0.9632,0.2689,0.0,0.9914,0.1305,
    0.0,0.0,1.0,-0.2588,0.0,0.9659,0.0,0.0,1.0,
    -0.2588,0.0,0.9659,0.0,0.0,1.0,-0.2588,0.0,0.9659,
    0.0,0.9632,0.2689,0.0338,0.9914,0.1261,0.0,0.9914,0.1305,
    0.0338,0.9914,0.1261,0.0,0.9632,0.2689,0.0696,0.9632,0.2597,
    0.2588,0.0,0.9659,0.0,0.0,1.0,0.2588,0.0,0.9659,
    0.0,0.0,1.0,0.2588,0.0,0.9659,0.0,0.0,1.0,
    0.0338,0.9914,0.1261,0.0,1.0,0.0,0.0,0.9914,0.1305,
    0.0652,0.9914,0.113,0.0,1.0,0.0,0.0338,0.9914,0.1261,
    0.0696,0.9632,0.2597,0.0652,0.9914,0.113,0.0338,0.9914,0.1261,
    0.0652,0.9914,0.113,0.0696,0.9632,0.2597,0.1344,0.9632,0.2329,
    0.5,0.0,0.866,0.2588,0.0,0.9659,0.5,0.0,0.866,
    0.2588,0.0,0.9659,0.5,0.0,0.866,0.2588,0.0,0.9659,
    0.1344,0.9632,0.2329,0.0923,0.9914,0.0923,0.0652,0.9914,0.113,
    0.0923,0.9914,0.0923,0.1344,0.9632,0.2329,0.1901,0.9632,0.1901,
    0.7071,0.0,0.7071,0.5,0.0,0.866,0.7071,0.0,0.7071,
    0.5,0.0,0.866,0.7071,0.0,0.7071,0.5,0.0,0.866,
    0.2329,0.9632,-0.1344,0.3592,0.8613,-0.3592,0.1901,0.9632,-0.1901,
    0.3592,0.8613,-0.3592,0.2329,0.9632,-0.1344,0.44,0.8613,-0.254,
    0.4907,0.8613,-0.1315,0.617,0.7017,-0.3562,0.44,0.8613,-0.254,
    0.617,0.7017,-0.3562,0.4907,0.8613,-0.1315,0.6882,0.7017,-0.1844,
    0.8391,0.4953,-0.2248,0.7125,0.7017,0.0,0.8687,0.4953,0.0,
    0.7125,0.7017,0.0,0.8391,0.4953,-0.2248,0.6882,0.7017,-0.1844,
    0.3592,0.8613,0.3592,0.2329,0.9632,0.1344,0.1901,0.9632,0.1901,
    0.2329,0.9632,0.1344,0.3592,0.8613,0.3592,0.44,0.8613,0.254,
    0.617,0.7017,0.3562,0.4907,0.8613,0.1315,0.44,0.8613,0.254,
    0.4907,0.8613,0.1315,0.617,0.7017,0.3562,0.6882,0.7017,0.1844,
    0.8687,0.4953,0.0,0.6882,0.7017,0.1844,0.8391,0.4953,0.2248,
    0.6882,0.7017,0.1844,0.8687,0.4953,0.0,0.7125,0.7017,0.0,
    0.1901,0.9632,-0.1901,0.254,0.8613,-0.44,0.1344,0.9632,-0.2329,
    0.254,0.8613,-0.44,0.1901,0.9632,-0.1901,0.3592,0.8613,-0.3592,
    0.1344,0.9632,-0.2329,0.1315,0.8613,-0.4907,0.0696,0.9632,-0.2597,
    0.1315,0.8613,-0.4907,0.1344,0.9632,-0.2329,0.254,0.8613,-0.44,
    0.0696,0.9632,-0.2597,0.0,0.8613,-0.508,0.0,0.9632,-0.2689,
    0.0,0.8613,-0.508,0.0696,0.9632,-0.2597,0.1315,0.8613,-0.4907,
    -0.0696,0.9632,-0.2597,0.0,0.8613,-0.508,-0.1315,0.8613,-0.4907,
    0.0,0.8613,-0.508,-0.0696,0.9632,-0.2597,0.0,0.9632,-0.2689,
    -0.1344,0.9632,-0.2329,-0.1315,0.8613,-0.4907,-0.254,0.8613,-0.44,
    -0.1315,0.8613,-0.4907,-0.1344,0.9632,-0.2329,-0.0696,0.9632,-0.2597,
    -0.1901,0.9632,-0.1901,-0.254,0.8613,-0.44,-0.3592,0.8613,-0.3592,
    -0.254,0.8613,-0.44,-0.1901,0.9632,-0.1901,-0.1344,0.9632,-0.2329,
    -0.2329,0.9632,-0.1344,-0.3592,0.8613,-0.3592,-0.44,0.8613,-0.254,
    -0.3592,0.8613,-0.3592,-0.2329,0.9632,-0.1344,-0.1901,0.9632,-0.1901,
    -0.2597,0.9632,-0.0696,-0.44,0.8613,-0.254,-0.4907,0.8613,-0.1315,
    -0.44,0.8613,-0.254,-0.2597,0.9632,-0.0696,-0.2329,0.9632,-0.1344,
    -0.2689,0.9632,0.0,-0.4907,0.8613,-0.1315,-0.508,0.8613,0.0,
    -0.4907,0.8613,-0.1315,-0.2689,0.9632,0.0,-0.2597,0.9632,-0.0696,
    -0.4907,0.8613,0.1315,-0.2689,0.9632,0.0,-0.508,0.8613,0.0,
    -0.2689,0.9632,0.0,-0.4907,0.8613,0.1315,-0.2597,0.9632,0.0696,
    -0.44,0.8613,0.254,-0.2597,0.9632,0.0696,-0.4907,0.8613,0.1315,
    -0.2597,0.9632,0.0696,-0.44,0.8613,0.254,-0.2329,0.9632,0.1344,
    -0.3592,0.8613,0.3592,-0.2329,0.9632,0.1344,-0.44,0.8613,0.254,
    -0.2329,0.9632,0.1344,-0.3592,0.8613,0.3592,-0.1901,0.9632,0.1901,
    -0.254,0.8613,0.44,-0.1901,0.9632,0.1901,-0.3592,0.8613,0.3592,
    -0.1901,0.9632,0.1901,-0.254,0.8613,0.44,-0.1344,0.9632,0.2329,
    -0.1315,0.8613,0.4907,-0.1344,0.9632,0.2329,-0.254,0.8613,0.44,
    -0.1344,0.9632,0.2329,-0.1315,0.8613,0.4907,-0.0696,0.9632,0.2597,
    0.0,0.8613,0.508,-0.0696,0.9632,0.2597,-0.1315,0.8613,0.4907,
    -0.0696,0.9632,0.2597,0.0,0.8613,0.508,0.0,0.9632,0.2689,
    0.1315,0.8613,0.4907,0.0,0.9632,0.2689,0.0,0.8613,0.508,
    0.0,0.9632,0.2689,0.1315,0.8613,0.4907,0.0696,0.9632,0.2597,
    0.1315,0.8613,0.4907,0.1344,0.9632,0.2329,0.0696,0.9632,0.2597,
    0.1344,0.9632,0.2329,0.1315,0.8613,0.4907,0.254,0.8613,0.44,
    0.254,0.8613,0.44,0.1901,0.9632,0.1901,0.1344,0.9632,0.2329,
    0.1901,0.9632,0.1901,0.254,0.8613,0.44,0.3592,0.8613,0.3592,
    0.44,0.8613,-0.254,0.5038,0.7017,-0.5038,0.3592,0.8613,-0.3592,
    0.5038,0.7017,-0.5038,0.44,0.8613,-0.254,0.617,0.7017,-0.3562,
    0.8391,0.4953,-0.2248,0.617,0.7017,-0.3562,0.6882,0.7017,-0.1844,
    0.617,0.7017,-0.3562,0.8391,0.4953,-0.2248,0.7523,0.4953,-0.4343,
    0.9337,0.2561,-0.2502,0.8687,0.4953,0.0,0.9666,0.2561,0.0,
    0.8687,0.4953,0.0,0.9337,0.2561,-0.2502,0.8391,0.4953,-0.2248,
    0.5038,0.7017,0.5038,0.44,0.8613,0.254,0.3592,0.8613,0.3592,
    0.44,0.8613,0.254,0.5038,0.7017,0.5038,0.617,0.7017,0.3562,
    0.8391,0.4953,0.2248,0.617,0.7017,0.3562,0.7523,0.4953,0.4343,
    0.617,0.7017,0.3562,0.8391,0.4953,0.2248,0.6882,0.7017,0.1844,
    0.9666,0.2561,0.0,0.8391,0.4953,0.2248,0.9337,0.2561,0.2502,
    0.8391,0.4953,0.2248,0.9666,0.2561,0.0,0.8687,0.4953,0.0,
    0.3592,0.8613,-0.3592,0.3562,0.7017,-0.617,0.254,0.8613,-0.44,
    0.3562,0.7017,-0.617,0.3592,0.8613,-0.3592,0.5038,0.7017,-0.5038,
    0.254,0.8613,-0.44,0.1844,0.7017,-0.6882,0.1315,0.8613,-0.4907,
    0.1844,0.7017,-0.6882,0.254,0.8613,-0.44,0.3562,0.7017,-0.617,
    0.1315,0.8613,-0.4907,0.0,0.7017,-0.7125,0.0,0.8613,-0.508,
    0.0,0.7017,-0.7125,0.1315,0.8613,-0.4907,0.1844,0.7017,-0.6882,
    -0.1315,0.8613,-0.4907,0.0,0.7017,-0.7125,-0.1844,0.7017,-0.6882,
    0.0,0.7017,-0.7125,-0.1315,0.8613,-0.4907,0.0,0.8613,-0.508,
    -0.254,0.8613,-0.44,-0.1844,0.7017,-0.6882,-0.3562,0.7017,-0.617,
    -0.1844,0.7017,-0.6882,-0.254,0.8613,-0.44,-0.1315,0.8613,-0.4907,
    -0.3592,0.8613,-0.3592,-0.3562,0.7017,-0.617,-0.5038,0.7017,-0.5038,
    -0.3562,0.7017,-0.617,-0.3592,0.8613,-0.3592,-0.254,0.8613,-0.44,
    -0.44,0.8613,-0.254,-0.5038,0.7017,-0.5038,-0.617,0.7017,-0.3562,
    -0.5038,0.7017,-0.5038,-0.44,0.8613,-0.254,-0.3592,0.8613,-0.3592,
    -0.4907,0.8613,-0.1315,-0.617,0.7017,-0.3562,-0.6882,0.7017,-0.1844,
    -0.617,0.7017,-0.3562,-0.4907,0.8613,-0.1315,-0.44,0.8613,-0.254,
    -0.508,0.8613,0.0,-0.6882,0.7017,-0.1844,-0.7125,0.7017,0.0,
    -0.6882,0.7017,-0.1844,-0.508,0.8613,0.0,-0.4907,0.8613,-0.1315,
    -0.6882,0.7017,0.1844,-0.508,0.8613,0.0,-0.7125,0.7017,0.0,
    -0.508,0.8613,0.0,-0.6882,0.7017,0.1844,-0.4907,0.8613,0.1315,
    -0.617,0.7017,0.3562,-0.4907,0.8613,0.1315,-0.6882,0.7017,0.1844,
    -0.4907,0.8613,0.1315,-0.617,0.7017,0.3562,-0.44,0.8613,0.254,
    -0.5038,0.7017,0.5038,-0.44,0.8613,0.254,-0.617,0.7017,0.3562,
    -0.44,0.8613,0.254,-0.5038,0.7017,0.5038,-0.3592,0.8613,0.3592,
    -0.3562,0.7017,0.617,-0.3592,0.8613,0.3592,-0.5038,0.7017,0.5038,
    -0.3592,0.8613,0.3592,-0.3562,0.7017,0.617,-0.254,0.8613,0.44,
    -0.1844,0.7017,0.6882,-0.254,0.8613,0.44,-0.3562,0.7017,0.617,
    -0.254,0.8613,0.44,-0.1844,0.7017,0.6882,-0.1315,0.8613,0.4907,
    0.0,0.7017,0.7125,-0.1315,0.8613,0.4907,-0.1844,0.7017,0.6882,
    -0.1315,0.8613,0.4907,0.0,0.7017,0.7125,0.0,0.8613,0.508,
    0.1844,0.7017,0.6882,0.0,0.8613,0.508,0.0,0.7017,0.7125,
    0.0,0.8613,0.508,0.1844,0.7017,0.6882,0.1315,0.8613,0.4907,
    0.1844,0.7017,0.6882,0.254,0.8613,0.44,0.1315,0.8613,0.4907,
    0.254,0.8613,0.44,0.1844,0.7017,0.6882,0.3562,0.7017,0.617,
    0.3562,0.7017,0.617,0.3592,0.8613,0.3592,0.254,0.8613,0.44,
    0.3592,0.8613,0.3592,0.3562,0.7017,0.617,0.5038,0.7017,0.5038,
    0.7523,0.4953,-0.4343,0.5038,0.7017,-0.5038,0.617,0.7017,-0.3562,
    0.5038,0.7017,-0.5038,0.7523,0.4953,-0.4343,0.6142,0.4953,-0.6142,
    0.9337,0.2561,-0.2502,0.7523,0.4953,-0.4343,0.8391,0.4953,-0.2248,
    0.7523,0.4953,-0.4343,0.9337,0.2561,-0.2502,0.8371,0.2561,-0.4833,
    0.9576,0.1305,-0.2566,0.9666,0.2561,0.0,0.9914,0.1305,0.0,
    0.9666,0.2561,0.0,0.9576,0.1305,-0.2566,0.9337,0.2561,-0.2502,
    0.7523,0.4953,0.4343,0.5038,0.7017,0.5038,0.6142,0.4953,0.6142,
    0.5038,0.7017,0.5038,0.7523,0.4953,0.4343,0.617,0.7017,0.3562,
    0.9337,0.2561,0.2502,0.7523,0.4953,0.4343,0.8371,0.2561,0.4833,
    0.7523,0.4953,0.4343,0.9337,0.2561,0.2502,0.8391,0.4953,0.2248,
    0.9914,0.1305,0.0,0.9337,0.2561,0.2502,0.9576,0.1305,0.2566,
    0.9337,0.2561,0.2502,0.9914,0.1305,0.0,0.9666,0.2561,0.0,
    0.3562,0.7017,-0.617,0.6142,0.4953,-0.6142,0.4343,0.4953,-0.7523,
    0.6142,0.4953,-0.6142,0.3562,0.7017,-0.617,0.5038,0.7017,-0.5038,
    0.1844,0.7017,-0.6882,0.4343,0.4953,-0.7523,0.2248,0.4953,-0.8391,
    0.4343,0.4953,-0.7523,0.1844,0.7017,-0.6882,0.3562,0.7017,-0.617,
    0.0,0.7017,-0.7125,0.2248,0.4953,-0.8391,0.0,0.4953,-0.8687,
    0.2248,0.4953,-0.8391,0.0,0.7017,-0.7125,0.1844,0.7017,-0.6882,
    -0.1844,0.7017,-0.6882,0.0,0.4953,-0.8687,-0.2248,0.4953,-0.8391,
    0.0,0.4953,-0.8687,-0.1844,0.7017,-0.6882,0.0,0.7017,-0.7125,
    -0.3562,0.7017,-0.617,-0.2248,0.4953,-0.8391,-0.4343,0.4953,-0.7523,
    -0.2248,0.4953,-0.8391,-0.3562,0.7017,-0.617,-0.1844,0.7017,-0.6882,
    -0.5038,0.7017,-0.5038,-0.4343,0.4953,-0.7523,-0.6142,0.4953,-0.6142,
    -0.4343,0.4953,-0.7523,-0.5038,0.7017,-0.5038,-0.3562,0.7017,-0.617,
    -0.5038,0.7017,-0.5038,-0.7523,0.4953,-0.4343,-0.617,0.7017,-0.3562,
    -0.7523,0.4953,-0.4343,-0.5038,0.7017,-0.5038,-0.6142,0.4953,-0.6142,
    -0.617,0.7017,-0.3562,-0.8391,0.4953,-0.2248,-0.6882,0.7017,-0.1844,
    -0.8391,0.4953,-0.2248,-0.617,0.7017,-0.3562,-0.7523,0.4953,-0.4343,
    -0.6882,0.7017,-0.1844,-0.8687,0.4953,0.0,-0.7125,0.7017,0.0,
    -0.8687,0.4953,0.0,-0.6882,0.7017,-0.1844,-0.8391,0.4953,-0.2248,
    -0.6882,0.7017,0.1844,-0.8687,0.4953,0.0,-0.8391,0.4953,0.2248,
    -0.8687,0.4953,0.0,-0.6882,0.7017,0.1844,-0.7125,0.7017,0.0,
    -0.617,0.7017,0.3562,-0.8391,0.4953,0.2248,-0.7523,0.4953,0.4343,
    -0.8391,0.4953,0.2248,-0.617,0.7017,0.3562,-0.6882,0.7017,0.1844,
    -0.5038,0.7017,0.5038,-0.7523,0.4953,0.4343,-0.6142,0.4953,0.6142,
    -0.7523,0.4953,0.4343,-0.5038,0.7017,0.5038,-0.617,0.7017,0.3562,
    -0.3562,0.7017,0.617,-0.6142,0.4953,0.6142,-0.4343,0.4953,0.7523,
    -0.6142,0.4953,0.6142,-0.3562,0.7017,0.617,-0.5038,0.7017,0.5038,
    -0.1844,0.7017,0.6882,-0.4343,0.4953,0.7523,-0.2248,0.4953,0.8391,
    -0.4343,0.4953,0.7523,-0.1844,0.7017,0.6882,-0.3562,0.7017,0.617,
    0.0,0.7017,0.7125,-0.2248,0.4953,0.8391,0.0,0.4953,0.8687,
    -0.2248,0.4953,0.8391,0.0,0.7017,0.7125,-0.1844,0.7017,0.6882,
    0.1844,0.7017,0.6882,0.0,0.4953,0.8687,0.2248,0.4953,0.8391,
    0.0,0.4953,0.8687,0.1844,0.7017,0.6882,0.0,0.7017,0.7125,
    0.3562,0.7017,0.617,0.2248,0.4953,0.8391,0.4343,0.4953,0.7523,
    0.2248,0.4953,0.8391,0.3562,0.7017,0.617,0.1844,0.7017,0.6882,
    0.5038,0.7017,0.5038,0.4343,0.4953,0.7523,0.6142,0.4953,0.6142,
    0.4343,0.4953,0.7523,0.5038,0.7017,0.5038,0.3562,0.7017,0.617,
    0.8371,0.2561,-0.4833,0.6142,0.4953,-0.6142,0.7523,0.4953,-0.4343,
    0.6142,0.4953,-0.6142,0.8371,0.2561,-0.4833,0.6835,0.2561,-0.6835,
    0.9576,0.1305,-0.2566,0.8371,0.2561,-0.4833,0.9337,0.2561,-0.2502,
    0.8371,0.2561,-0.4833,0.9576,0.1305,-0.2566,0.8586,0.1305,-0.4957,
    0.8371,0.2561,0.4833,0.6142,0.4953,0.6142,0.6835,0.2561,0.6835,
    0.6142,0.4953,0.6142,0.8371,0.2561,0.4833,0.7523,0.4953,0.4343,
    0.9576,0.1305,0.2566,0.8371,0.2561,0.4833,0.8586,0.1305,0.4957,
    0.8371,0.2561,0.4833,0.9576,0.1305,0.2566,0.9337,0.2561,0.2502,
    0.4343,0.4953,-0.7523,0.6835,0.2561,-0.6835,0.4833,0.2561,-0.8371,
    0.6835,0.2561,-0.6835,0.4343,0.4953,-0.7523,0.6142,0.4953,-0.6142,
    0.2248,0.4953,-0.8391,0.4833,0.2561,-0.8371,0.2502,0.2561,-0.9337,
    0.4833,0.2561,-0.8371,0.2248,0.4953,-0.8391,0.4343,0.4953,-0.7523,
    0.0,0.4953,-0.8687,0.2502,0.2561,-0.9337,0.0,0.2561,-0.9666,
    0.2502,0.2561,-0.9337,0.0,0.4953,-0.8687,0.2248,0.4953,-0.8391,
    -0.2248,0.4953,-0.8391,0.0,0.2561,-0.9666,-0.2502,0.2561,-0.9337,
    0.0,0.2561,-0.9666,-0.2248,0.4953,-0.8391,0.0,0.4953,-0.8687,
    -0.4343,0.4953,-0.7523,-0.2502,0.2561,-0.9337,-0.4833,0.2561,-0.8371,
    -0.2502,0.2561,-0.9337,-0.4343,0.4953,-0.7523,-0.2248,0.4953,-0.8391,
    -0.6142,0.4953,-0.6142,-0.4833,0.2561,-0.8371,-0.6835,0.2561,-0.6835,
    -0.4833,0.2561,-0.8371,-0.6142,0.4953,-0.6142,-0.4343,0.4953,-0.7523,
    -0.6142,0.4953,-0.6142,-0.8371,0.2561,-0.4833,-0.7523,0.4953,-0.4343,
    -0.8371,0.2561,-0.4833,-0.6142,0.4953,-0.6142,-0.6835,0.2561,-0.6835,
    -0.7523,0.4953,-0.4343,-0.9337,0.2561,-0.2502,-0.8391,0.4953,-0.2248,
    -0.9337,0.2561,-0.2502,-0.7523,0.4953,-0.4343,-0.8371,0.2561,-0.4833,
    -0.8391,0.4953,-0.2248,-0.9666,0.2561,0.0,-0.8687,0.4953,0.0,
    -0.9666,0.2561,0.0,-0.8391,0.4953,-0.2248,-0.9337,0.2561,-0.2502,
    -0.8391,0.4953,0.2248,-0.9666,0.2561,0.0,-0.9337,0.2561,0.2502,
    -0.9666,0.2561,0.0,-0.8391,0.4953,0.2248,-0.8687,0.4953,0.0,
    -0.7523,0.4953,0.4343,-0.9337,0.2561,0.2502,-0.8371,0.2561,0.4833,
    -0.9337,0.2561,0.2502,-0.7523,0.4953,0.4343,-0.8391,0.4953,0.2248,
    -0.6142,0.4953,0.6142,-0.8371,0.2561,0.4833,-0.6835,0.2561,0.6835,
    -0.8371,0.2561,0.4833,-0.6142,0.4953,0.6142,-0.7523,0.4953,0.4343,
    -0.4343,0.4953,0.7523,-0.6835,0.2561,0.6835,-0.4833,0.2561,0.8371,
    -0.6835,0.2561,0.6835,-0.4343,0.4953,0.7523,-0.6142,0.4953,0.6142,
    -0.2248,0.4953,0.8391,-0.4833,0.2561,0.8371,-0.2502,0.2561,0.9337,
    -0.4833,0.2561,0.8371,-0.2248,0.4953,0.8391,-0.4343,0.4953,0.7523,
    0.0,0.4953,0.8687,-0.2502,0.2561,0.9337,0.0,0.2561,0.9666,
    -0.2502,0.2561,0.9337,0.0,0.4953,0.8687,-0.2248,0.4953,0.8391,
    0.2248,0.4953,0.8391,0.0,0.2561,0.9666,0.2502,0.2561,0.9337,
    0.0,0.2561,0.9666,0.2248,0.4953,0.8391,0.0,0.4953,0.8687,
    0.4343,0.4953,0.7523,0.2502,0.2561,0.9337,0.4833,0.2561,0.8371,
    0.2502,0.2561,0.9337,0.4343,0.4953,0.7523,0.2248,0.4953,0.8391,
    0.6142,0.4953,0.6142,0.4833,0.2561,0.8371,0.6835,0.2561,0.6835,
    0.4833,0.2561,0.8371,0.6142,0.4953,0.6142,0.4343,0.4953,0.7523,
    0.8586,0.1305,-0.4957,0.6835,0.2561,-0.6835,0.8371,0.2561,-0.4833,
    0.6835,0.2561,-0.6835,0.8586,0.1305,-0.4957,0.701,0.1305,-0.701,
    0.8586,0.1305,0.4957,0.6835,0.2561,0.6835,0.701,0.1305,0.701,
    0.6835,0.2561,0.6835,0.8586,0.1305,0.4957,0.8371,0.2561,0.4833,
    0.4833,0.2561,-0.8371,0.701,0.1305,-0.701,0.4957,0.1305,-0.8586,
    0.701,0.1305,-0.701,0.4833,0.2561,-0.8371,0.6835,0.2561,-0.6835,
    0.2502,0.2561,-0.9337,0.4957,0.1305,-0.8586,0.2566,0.1305,-0.9576,
    0.4957,0.1305,-0.8586,0.2502,0.2561,-0.9337,0.4833,0.2561,-0.8371,
    0.0,0.2561,-0.9666,0.2566,0.1305,-0.9576,0.0,0.1305,-0.9914,
    0.2566,0.1305,-0.9576,0.0,0.2561,-0.9666,0.2502,0.2561,-0.9337,
    -0.2502,0.2561,-0.9337,0.0,0.1305,-0.9914,-0.2566,0.1305,-0.9576,
    0.0,0.1305,-0.9914,-0.2502,0.2561,-0.9337,0.0,0.2561,-0.9666,
    -0.4833,0.2561,-0.8371,-0.2566,0.1305,-0.9576,-0.4957,0.1305,-0.8586,
    -0.2566,0.1305,-0.9576,-0.4833,0.2561,-0.8371,-0.2502,0.2561,-0.9337,
    -0.6835,0.2561,-0.6835,-0.4957,0.1305,-0.8586,-0.701,0.1305,-0.701,
    -0.4957,0.1305,-0.8586,-0.6835,0.2561,-0.6835,-0.4833,0.2561,-0.8371,
    -0.6835,0.2561,-0.6835,-0.8586,0.1305,-0.4957,-0.8371,0.2561,-0.4833,
    -0.8586,0.1305,-0.4957,-0.6835,0.2561,-0.6835,-0.701,0.1305,-0.701,
    -0.8371,0.2561,-0.4833,-0.9576,0.1305,-0.2566,-0.9337,0.2561,-0.2502,
    -0.9576,0.1305,-0.2566,-0.8371,0.2561,-0.4833,-0.8586,0.1305,-0.4957,
    -0.9337,0.2561,-0.2502,-0.9914,0.1305,0.0,-0.9666,0.2561,0.0,
    -0.9914,0.1305,0.0,-0.9337,0.2561,-0.2502,-0.9576,0.1305,-0.2566,
    -0.9337,0.2561,0.2502,-0.9914,0.1305,0.0,-0.9576,0.1305,0.2566,
    -0.9914,0.1305,0.0,-0.9337,0.2561,0.2502,-0.9666,0.2561,0.0,
    -0.8371,0.2561,0.4833,-0.9576,0.1305,0.2566,-0.8586,0.1305,0.4957,
    -0.9576,0.1305,0.2566,-0.8371,0.2561,0.4833,-0.9337,0.2561,0.2502,
    -0.6835,0.2561,0.6835,-0.8586,0.1305,0.4957,-0.701,0.1305,0.701,
    -0.8586,0.1305,0.4957,-0.6835,0.2561,0.6835,-0.8371,0.2561,0.4833,
    -0.4833,0.2561,0.8371,-0.701,0.1305,0.701,-0.4957,0.1305,0.8586,
    -0.701,0.1305,0.701,-0.4833,0.2561,0.8371,-0.6835,0.2561,0.6835,
    -0.2502,0.2561,0.9337,-0.4957,0.1305,0.8586,-0.2566,0.1305,0.9576,
    -0.4957,0.1305,0.8586,-0.2502,0.2561,0.9337,-0.4833,0.2561,0.8371,
    0.0,0.2561,0.9666,-0.2566,0.1305,0.9576,0.0,0.1305,0.9914,
    -0.2566,0.1305,0.9576,0.0,0.2561,0.9666,-0.2502,0.2561,0.9337,
    0.2502,0.2561,0.9337,0.0,0.1305,0.9914,0.2566,0.1305,0.9576,
    0.0,0.1305,0.9914,0.2502,0.2561,0.9337,0.0,0.2561,0.9666,
    0.4833,0.2561,0.8371,0.2566,0.1305,0.9576,0.4957,0.1305,0.8586,
    0.2566,0.1305,0.9576,0.4833,0.2561,0.8371,0.2502,0.2561,0.9337,
    0.6835,0.2561,0.6835,0.4957,0.1305,0.8586,0.701,0.1305,0.701,
    0.4957,0.1305,0.8586,0.6835,0.2561,0.6835,0.4833,0.2561,0.8371,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,-1.0,0.0,0.0,-1.0,0.0,0.0,-1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.0,1.0,0.0,0.0,1.0,0.0,0.0,1.0,0.0,
    0.866,0.0,-0.5,0.9659,0.0,-0.2588,0.9659,0.0,-0.2588,
    0.9659,0.0,-0.2588,0.866,0.0,-0.5,0.866,0.0,-0.5,
    0.9659,0.0,-0.2588,1.0,0.0,0.0,1.0,0.0,0.0,
    1.0,0.0,0.0,0.9659,0.0,-0.2588,0.9659,0.0,-0.2588,
    1.0,0.0,0.0,0.9659,0.0,0.2588,0.9659,0.0,0.2588,
    0.9659,0.0,0.2588,1.0,0.0,0.0,1.0,0.0,0.0,
    0.9659,0.0,0.2588,0.866,0.0,0.5,0.866,0.0,0.5,
    0.866,0.0,0.5,0.9659,0.0,0.2588,0.9659,0.0,0.2588,
    0.866,0.0,0.5,0.7071,0.0,0.7071,0.7071,0.0,0.7071,
    0.7071,0.0,0.7071,0.866,0.0,0.5,0.866,0.0,0.5,
    0.7071,0.0,0.7071,0.5,0.0,0.866,0.7071,0.0,0.7071,
    0.5,0.0,0.866,0.7071,0.0,0.7071,0.5,0.0,0.866,
    0.5,0.0,0.866,0.2588,0.0,0.9659,0.5,0.0,0.866,
    0.2588,0.0,0.9659,0.5,0.0,0.866,0.2588,0.0,0.9659,
    0.2588,0.0,0.9659,0.0,0.0,1.0,0.2588,0.0,0.9659,
    0.0,0.0,1.0,0.2588,0.0,0.9659,0.0,0.0,1.0,
    0.0,0.0,1.0,-0.2588,0.0,0.9659,0.0,0.0,1.0,
    -0.2588,0.0,0.9659,0.0,0.0,1.0,-0.2588,0.0,0.9659,
    -0.2588,0.0,0.9659,-0.5,0.0,0.866,-0.2588,0.0,0.9659,
    -0.5,0.0,0.866,-0.2588,0.0,0.9659,-0.5,0.0,0.866,
    -0.5,0.0,0.866,-0.7071,0.0,0.7071,-0.5,0.0,0.866,
    -0.7071,0.0,0.7071,-0.5,0.0,0.866,-0.7071,0.0,0.7071,
    -0.866,0.0,0.5,-0.7071,0.0,0.7071,-0.7071,0.0,0.7071,
    -0.7071,0.0,0.7071,-0.866,0.0,0.5,-0.866,0.0,0.5,
    -0.9659,0.0,0.2588,-0.866,0.0,0.5,-0.866,0.0,0.5,
    -0.866,0.0,0.5,-0.9659,0.0,0.2588,-0.9659,0.0,0.2588,
    -1.0,0.0,0.0,-0.9659,0.0,0.2588,-0.9659,0.0,0.2588,
    -0.9659,0.0,0.2588,-1.0,0.0,0.0,-1.0,0.0,0.0,
    -0.9659,0.0,-0.2588,-1.0,0.0,0.0,-1.0,0.0,0.0,
    -1.0,0.0,0.0,-0.9659,0.0,-0.2588,-0.9659,0.0,-0.2588,
    -0.866,0.0,-0.5,-0.9659,0.0,-0.2588,-0.9659,0.0,-0.2588,
    -0.9659,0.0,-0.2588,-0.866,0.0,-0.5,-0.866,0.0,-0.5,
    -0.7071,0.0,-0.7071,-0.866,0.0,-0.5,-0.866,0.0,-0.5,
    -0.866,0.0,-0.5,-0.7071,0.0,-0.7071,-0.7071,0.0,-0.7071,
    -0.7071,0.0,-0.7071,-0.5,0.0,-0.866,-0.7071,0.0,-0.7071,
    -0.5,0.0,-0.866,-0.7071,0.0,-0.7071,-0.5,0.0,-0.866,
    -0.5,0.0,-0.866,-0.2588,0.0,-0.9659,-0.5,0.0,-0.866,
    -0.2588,0.0,-0.9659,-0.5,0.0,-0.866,-0.2588,0.0,-0.9659,
    -0.2588,0.0,-0.9659,0.0,0.0,-1.0,-0.2588,0.0,-0.9659,
    0.0,0.0,-1.0,-0.2588,0.0,-0.9659,0.0,0.0,-1.0,
    0.0,0.0,-1.0,0.2588,0.0,-0.9659,0.0,0.0,-1.0,
    0.2588,0.0,-0.9659,0.0,0.0,-1.0,0.2588,0.0,-0.9659,
    0.2588,0.0,-0.9659,0.5,0.0,-0.866,0.2588,0.0,-0.9659,
    0.5,0.0,-0.866,0.2588,0.0,-0.9659,0.5,0.0,-0.866,
    0.5,0.0,-0.866,0.7071,0.0,-0.7071,0.5,0.0,-0.866,
    0.7071,0.0,-0.7071,0.5,0.0,-0.866,0.7071,0.0,-0.7071,
    0.7071,0.0,-0.7071,0.866,0.0,-0.5,0.866,0.0,-0.5,
    0.866,0.0,-0.5,0.7071,0.0,-0.7071,0.7071,0.0,-0.7071,
];
