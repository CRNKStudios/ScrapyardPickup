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
    var modelViewProjectionMatrix3:GLKMatrix4 = GLKMatrix4Identity
    var normalMatrix3: GLKMatrix3 = GLKMatrix3Identity
    var rotation: Float = 0.0
    
    var vertexArray: GLuint = 0
    var vertexBuffer: GLuint = 0
    var vertexArray2: GLuint = 0
    var vertexBuffer2: GLuint = 0
    var vertexArray3: GLuint = 0
    var vertexBuffer3: GLuint = 0
    
    var context: EAGLContext? = nil
    var effect: GLKBaseEffect? = nil
    var magnetIsOn = false;
    var magnetStrength: GLfloat = 15.0;
    var blockActivated: Bool = false;
    var timer = 0.0
    
// MARK: Create objects
    var playerMagnet: PlayerObject = PlayerObject()
    var playerCube: GameObject = GameObject()
    var ground: GameObject = GameObject()
    
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
            
// MARK: Create Cube on Button press
            let cubeVertexData = playerCube.getObjectData()
            glGenVertexArraysOES(1, &vertexArray2)
            glBindVertexArrayOES(vertexArray2)
            
            glGenBuffers(1, &vertexBuffer2)
            glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer2)
            glBindVertexArrayOES(vertexArray2)
            
            glBufferData(GLenum(GL_ARRAY_BUFFER), GLsizeiptr(MemoryLayout<GLfloat>.size * cubeVertexData.position.count + MemoryLayout<GLfloat>.size * cubeVertexData.normal.count), nil, GLenum(GL_STATIC_DRAW))
           
            glBufferSubData(GLenum(GL_ARRAY_BUFFER), 0, GLsizeiptr(MemoryLayout<GLfloat>.size * cubeVertexData.position.count), playerCube.getPositionsData()) // target, offset, size, data
            glBufferSubData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<GLfloat>.size * cubeVertexData.position.count, GLsizeiptr(MemoryLayout<GLfloat>.size * cubeVertexData.normal.count), playerCube.getNormalsData()) // target, offset, size, data
            
            glEnableVertexAttribArray(GLuint(GLKVertexAttrib.position.rawValue))
            // Index, size, type, normalized, stride, pointer
            glVertexAttribPointer(GLuint(GLKVertexAttrib.position.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, BUFFER_OFFSET(0))
            glEnableVertexAttribArray(GLuint(GLKVertexAttrib.normal.rawValue))
            glVertexAttribPointer(GLuint(GLKVertexAttrib.normal.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, BUFFER_OFFSET(0))
            
            glDrawArrays(GLenum(GL_TRIANGLES), 0, GLsizei(cubeVertexData.position.count))
            blockActivated=true;
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
        
        // MARK: Magnet Object Creation
        glGenVertexArraysOES(1, &vertexArray)
        glBindVertexArrayOES(vertexArray)
        
        glGenBuffers(1, &vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        
        playerMagnet = PlayerObject(name: "CraneModel", tag: "Player", objectData: ModelObject.parseOBJFileToModel(fileName: "CraneModel")
.getModelData(), 0, 2, 0, scale: 1, baseMatrix: GLKMatrix4Identity)
        
        //Get the vertex data from the playermagnet object for drawing
        let playerVertexData: VertexData = playerMagnet.getObjectData()
        
        glBufferData(GLenum(GL_ARRAY_BUFFER), GLsizeiptr(MemoryLayout<GLfloat>.size * playerVertexData.position.count * 3), nil, GLenum(GL_STATIC_DRAW))
        
        glBufferSubData(GLenum(GL_ARRAY_BUFFER), 0, MemoryLayout<GLfloat>.size * playerVertexData.position.count, playerMagnet.getPositionsData());
        glBufferSubData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<GLfloat>.size * playerVertexData.position.count, MemoryLayout<GLfloat>.size * playerVertexData.texture.count, playerMagnet.getTexturesData());
        glBufferSubData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<GLfloat>.size * playerVertexData.position.count * 2, MemoryLayout<GLfloat>.size * playerVertexData.normal.count, playerMagnet.getNormalsData());
        
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.position.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.position.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, BUFFER_OFFSET(0))
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.normal.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.normal.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, BUFFER_OFFSET(0))
        
        // MARK: Cube Object Loaded
        playerCube = GameObject(name: "Cube", tag: "Scrap", objectData: ModelObject.parseOBJFileToModel(fileName: "monkey").getModelData(), 0.0, -2.0, 0.0, scale: 0.5, baseMatrix: GLKMatrix4Identity)
        
        // MARK: Ground Object Creation
        glGenVertexArraysOES(1, &vertexArray3)
        glBindVertexArrayOES(vertexArray3)
        
        glGenBuffers(1, &vertexBuffer3)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer3)
        
        ground = GameObject(name: "Ground", tag: "Ground", objectData: ModelObject.parseOBJFileToModel(fileName: "cube").getModelData(), 0.0, -4, 0.0, scale: 1, baseMatrix: GLKMatrix4Identity)
        
        //Get the vertex data from the playermagnet object for drawing
        let groundVertexData: VertexData = ground.getObjectData()
        
        glBufferData(GLenum(GL_ARRAY_BUFFER), GLsizeiptr(MemoryLayout<GLfloat>.size * groundVertexData.position.count * 3), nil, GLenum(GL_STATIC_DRAW))
        
        glBufferSubData(GLenum(GL_ARRAY_BUFFER), 0, MemoryLayout<GLfloat>.size * groundVertexData.position.count, ground.getPositionsData());
        glBufferSubData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<GLfloat>.size * groundVertexData.position.count, MemoryLayout<GLfloat>.size * groundVertexData.texture.count, ground.getTexturesData());
        glBufferSubData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<GLfloat>.size * groundVertexData.position.count * 2, MemoryLayout<GLfloat>.size * groundVertexData.normal.count, ground.getNormalsData());
        
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
        if(magnetIsOn){
            var xdiff = playerMagnet.position.x-playerCube.position.x;
            var ydiff = playerMagnet.position.y-playerCube.position.y;
            var zdiff = playerMagnet.position.z-playerCube.position.z;
            var magnitude = sqrt(xdiff*xdiff+ydiff*ydiff+zdiff*zdiff);
            xdiff = xdiff/magnitude;
            ydiff = ydiff/magnitude;
            zdiff = zdiff/magnitude;
            playerCube.addToVelocities(velx: magnetStrength*xdiff*Float(self.timeSinceLastUpdate), vely: magnetStrength*ydiff*Float(self.timeSinceLastUpdate), velz: magnetStrength*zdiff*Float(self.timeSinceLastUpdate));
        }
        
        var magnetBox: HitBox = HitBox(left:-0.6, right:0.1, top:0.1, bottom:-1.2, front:1.2, back:-1.2);
        var junkHitBox: HitBox = HitBox(left:-0.5, right:0.5, top:0.5, bottom:-0.5, front:0.5, back:-0.5);
        
        //print(playerCube.velocity);
        //print("collision: ",HitBox.collisionHasOccured(firstPos: playerMagnet.position, firstBox: magnetBox, secondPos: playerCube.position, secondBox: junkHitBox));
        
        if(HitBox.collisionHasOccured(firstPos: playerMagnet.position, firstBox: magnetBox, secondPos: playerCube.position, secondBox: junkHitBox)&&blockActivated){
            var magnetVel = Vector4(x:0,y:0,z:0,w:0)
            Physics.calculateCollision(ui: &magnetVel, firstPos: playerMagnet.position, firstBox: magnetBox, vi: &playerCube.velocity, secondPos: playerCube.position, secondBox: junkHitBox, mass1: 1000, mass2: 1)
        }
        
        
        playerCube.addToVelocities(velx: 0, vely: Float(-9.81*self.timeSinceLastUpdate), velz: 0);
        playerCube.updatePosition(deltaTime: GLfloat(self.timeSinceLastUpdate));
        var modelViewMatrix = playerMagnet.getTranslationMatrix();
        var modelViewMatrix2 = playerCube.getTranslationMatrix();
        var modelViewMatrix3 = ground.getTranslationMatrix()
        modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, 0, -2.5, 0)
        modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, 0.5, 0.5, 0.5)
        modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix)
        modelViewMatrix2 = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix2)
        modelViewMatrix3 = GLKMatrix4Scale(modelViewMatrix3, 1000, 0.5, 1000)
        modelViewMatrix3 = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix3)
        
        projectionMatrix = GLKMatrix4RotateX(projectionMatrix, 0.5);
        let worldTranslationMatrix = GLKMatrix4MakeTranslation(0.0,  0.0, -3.0)
        projectionMatrix = GLKMatrix4Multiply(projectionMatrix, worldTranslationMatrix)
        
        normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), nil)
        normalMatrix2 = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix2), nil)
        
        modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix)
        modelViewProjectionMatrix2 = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix2)
        modelViewProjectionMatrix3 = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix3)
        
        //rotation += Float(self.timeSinceLastUpdate * 0.5)
        self.updateTimer(dt: self.timeSinceLastUpdate)
    }
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glClearColor(0.65, 0.65, 0.65, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT) | GLbitfield(GL_DEPTH_BUFFER_BIT))
        
        // Render the object with GLKit
        //self.effect?.prepareToDraw()
        
        //glDrawArrays(GLenum(GL_TRIANGLES) , 0, 36)
        
        // Render the object again with ES2
        glUseProgram(program)
        
        glBindVertexArrayOES(vertexArray)
        
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
        
        glDrawArrays(GLenum(GL_TRIANGLES), 0, GLsizei(playerMagnet.getObjectData().position.count))
        
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

        glDrawArrays(GLenum(GL_TRIANGLES), 0, GLsizei(playerCube.getObjectData().position.count))
        
        glBindVertexArrayOES(vertexArray3)
        
        withUnsafePointer(to: &modelViewProjectionMatrix3, {
            $0.withMemoryRebound(to: Float.self, capacity: 16, {
                glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, $0)
            })
        })
        
        withUnsafePointer(to: &normalMatrix3, {
            $0.withMemoryRebound(to: Float.self, capacity: 9, {
                glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, $0)
            })
        })
        
        glDrawArrays(GLenum(GL_TRIANGLES), 0, GLsizei(ground.getObjectData().position.count))
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
