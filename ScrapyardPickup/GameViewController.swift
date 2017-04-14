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
    
    
    // MARK: Create objects
    var playerMagnet: PlayerObject = PlayerObject()
    var playerCube: GameObject = GameObject()
    var ground: GameObject = GameObject()
    var scrapObjects: [GameObject] = []
    var grinderBox: GameObject = GameObject()
    var grinderBlades: GameObject = GameObject()
    var pp: PlayerPrefs = PlayerPrefs(name: "player")
    
    // TODO: Fix this. Each object should hold it's own projviewmatrix && normal
    var modelViewProjectionMatrix:GLKMatrix4 = GLKMatrix4Identity
    var normalMatrix: GLKMatrix3 = GLKMatrix3Identity
    var modelViewProjectionMatrix2:GLKMatrix4 = GLKMatrix4Identity
    var normalMatrix2: GLKMatrix3 = GLKMatrix3Identity
    var modelViewProjectionMatrix3:GLKMatrix4 = GLKMatrix4Identity
    var normalMatrix3: GLKMatrix3 = GLKMatrix3Identity
    var modelViewProjectionMatrix4:GLKMatrix4 = GLKMatrix4Identity
    var normalMatrix4: GLKMatrix3 = GLKMatrix3Identity
    var modelViewProjectionMatrix5:GLKMatrix4 = GLKMatrix4Identity
    var normalMatrix5: GLKMatrix3 = GLKMatrix3Identity
    var modelViewProjectionMatrix6:GLKMatrix4 = GLKMatrix4Identity
    var normalMatrix6: GLKMatrix3 = GLKMatrix3Identity
    var rotation: Float = 0.0
    
    var context: EAGLContext? = nil
    var effect: GLKBaseEffect? = nil
    var magnetIsOn = false;
    var magnetStrength: GLfloat = 15.0; // Is this where the model stuff goes?
    var blockActivated: Bool = false;
    var timer = 0.0
    var movingUp = false;
    var movingDown = false;
    var movingLeft = false;
    var movingRight = false;
    
    var soundManager: SoundManager = SoundManager()
    
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
        
        soundManager.playSound(fileName: "track_3")
        
        self.setupGL()
    }
    
    //connect UI buttons to funtions
    func initButtons(){
        UIButtonUp.tag = Buttons.BUTTON_UP.rawValue;
        UIButtonUp.addTarget(self,action:#selector(buttonClicked),for:.touchDown);
        UIButtonUp.addTarget(self,action:#selector(buttonReleased),for:.touchUpInside);
        UIButtonUp.addTarget(self,action:#selector(buttonReleased),for:.touchUpOutside);
        
        UIButtonDown.tag = Buttons.BUTTON_DOWN.rawValue;
        UIButtonDown.addTarget(self,action:#selector(buttonClicked),for:.touchDown);
        UIButtonDown.addTarget(self,action:#selector(buttonReleased),for:.touchUpInside);
        UIButtonDown.addTarget(self,action:#selector(buttonReleased),for:.touchUpOutside);
        
        UIButtonLeft.tag = Buttons.BUTTON_LEFT.rawValue;
        UIButtonLeft.addTarget(self,action:#selector(buttonClicked),for:.touchDown);
        UIButtonLeft.addTarget(self,action:#selector(buttonReleased),for:.touchUpInside);
        UIButtonLeft.addTarget(self,action:#selector(buttonReleased),for:.touchUpOutside);
        
        UIButtonRight.tag = Buttons.BUTTON_RIGHT.rawValue;
        UIButtonRight.addTarget(self,action:#selector(buttonClicked),for:.touchDown);
        UIButtonRight.addTarget(self,action:#selector(buttonReleased),for:.touchUpInside);
        UIButtonRight.addTarget(self,action:#selector(buttonReleased),for:.touchUpOutside);
        
        UIButtonMagnetPower.tag = Buttons.BUTTON_MAGNET_POWER.rawValue;
        UIButtonMagnetPower.addTarget(self,action:#selector(buttonClicked),for:.touchDown);
        UIButtonMagnetPower.addTarget(self,action:#selector(buttonReleased),for:.touchUpInside);
    }
    
    func buttonClicked(sender:UIButton)
    {
        switch(sender.tag){
        case Buttons.BUTTON_UP.rawValue:
            movingUp = true;
            soundManager.playSound(fileName: "Machine Whirring SOUND Effect");
            break;
        case Buttons.BUTTON_DOWN.rawValue:
            soundManager.playSound(fileName: "Machine Whirring SOUND Effect");
            movingDown = true;
            break;
        case Buttons.BUTTON_LEFT.rawValue:
            soundManager.playSound(fileName: "Machine Whirring SOUND Effect");
            movingLeft = true;
            break;
        case Buttons.BUTTON_RIGHT.rawValue:
            soundManager.playSound(fileName: "Machine Whirring SOUND Effect");
            movingRight = true;
            break;
        case Buttons.BUTTON_MAGNET_POWER.rawValue:
            soundManager.playSound(fileName: "Machine Whirring Sound Effect Magnet");
            print("magnet power on");
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
        case Buttons.BUTTON_UP.rawValue:
            movingUp = false;
            break;
        case Buttons.BUTTON_DOWN.rawValue:
            movingDown = false;
            break;
        case Buttons.BUTTON_LEFT.rawValue:
            movingLeft = false;
            break;
        case Buttons.BUTTON_RIGHT.rawValue:
            movingRight = false;
            break;

        case Buttons.BUTTON_MAGNET_POWER.rawValue:
            print("magnet power off");
            magnetIsOn=false;
            break;
        default:
            break;
        }
        soundManager.stopSound();
        
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
        playerMagnet = PlayerObject(name: "CraneModel", tag: "Player", vertexArray: 0, vertexBuffer: 0, objectData: ModelObject.parseOBJFileToModel(fileName: "CraneModel")
.getModelData(), 0, 4, -8, scale: 1, baseMatrix: GLKMatrix4Identity)
        self.loadObjectsToBuffers(go: playerMagnet)
        
        // MARK: Cube Object Loaded
//        playerCube = GameObject(name: "Cube", tag: "Scrap", vertexArray: 0, vertexBuffer: 0, objectData: ModelObject.parseOBJFileToModel(fileName: "monkey").getModelData(), 0.0, -2.0, 0.0, scale: 0.5, baseMatrix: GLKMatrix4Identity)
//        self.loadObjectsToBuffers(go: playerCube)
        
        grinderBox = GameObject(name: "Buster", tag: "Grinder", vertexArray: 0, vertexBuffer: 0, objectData: ModelObject.parseOBJFileToModel(fileName: "junkyardGrinderBoxNoTex").getModelData(), -2.0, -1.0, 0.0, scale: 1.0, baseMatrix: GLKMatrix4Identity);
        self.loadObjectsToBuffers(go: grinderBox)
        
        grinderBlades = GameObject(name: "Blades", tag: "Grinder", vertexArray: 0, vertexBuffer: 0, objectData: ModelObject.parseOBJFileToModel(fileName: "junkyardGrinderBladesNoTex").getModelData(), -2.0, -1.0, 0.0, scale: 1.0, baseMatrix: GLKMatrix4Identity);
        self.loadObjectsToBuffers(go: grinderBlades)
        
        // MARK: Ground Object Creation
        ground = GameObject(name: "Ground", tag: "Ground", vertexArray: 0, vertexBuffer: 0, objectData: ModelObject.parseOBJFileToModel(fileName: "cube").getModelData(), 0.0, -2.0, 0.0, scale: 1, baseMatrix: GLKMatrix4Identity)
        self.loadObjectsToBuffers(go: ground)
        
        // MARK: Create scrap objects
        // TODO: Change the level to the one the user selected
        scrapObjects = ScrapFactory.generateScrapObjects(level: 1)
        // TODO: Put in a different vertex array (same as others?)
        self.generateScrapObjects(objs: scrapObjects)
        
        glBindVertexArrayOES(0)
    }
    
    func loadObjectsToBuffers(go: GameObject) {
        glGenVertexArraysOES(1, &go.vertexArray)
        glBindVertexArrayOES(go.vertexArray)
        
        glGenBuffers(1, &go.vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), go.vertexBuffer)
        
        let objectData: VertexData = go.getObjectData()
        
        glBufferData(GLenum(GL_ARRAY_BUFFER), GLsizeiptr(MemoryLayout<GLfloat>.size * objectData.position.count * 3), nil, GLenum(GL_STATIC_DRAW))
        
        glBufferSubData(GLenum(GL_ARRAY_BUFFER), 0, MemoryLayout<GLfloat>.size * objectData.position.count, go.getPositionsData());
        glBufferSubData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<GLfloat>.size * objectData.position.count, MemoryLayout<GLfloat>.size * objectData.texture.count, go.getTexturesData());
        glBufferSubData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<GLfloat>.size * objectData.position.count * 2, MemoryLayout<GLfloat>.size * objectData.normal.count, go.getNormalsData());
        
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.position.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.position.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, BUFFER_OFFSET(0))
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.normal.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.normal.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, BUFFER_OFFSET(0))
        
        glBindVertexArrayOES(0)
    }

    func generateScrapObjects(objs: [GameObject]) {
        for obj in objs {
            self.loadObjectsToBuffers(go: obj)
        }
    }
    
    func endLevel() {
        print("Ending level...")
        LevelManager.endLevel(score: pp.getScore(), level: pp.curLevel);
        tearDownGL()
        _ = navigationController?.popViewController(animated: true)
    }
    
    func tearDownGL() {
        EAGLContext.setCurrent(self.context)
        
        // TODO: Delete all buffers of objects
        glDeleteBuffers(1, &playerMagnet.vertexBuffer)
        glDeleteVertexArraysOES(1, &playerMagnet.vertexArray)
        glDeleteBuffers(1, &playerCube.vertexBuffer)
        glDeleteVertexArraysOES(1, &playerCube.vertexArray)
        glDeleteBuffers(1, &ground.vertexBuffer)
        glDeleteVertexArraysOES(1, &ground.vertexArray)
        
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
        projectionMatrix = GLKMatrix4RotateX(projectionMatrix, GLKMathDegreesToRadians(30))
        
        self.effect?.transform.projectionMatrix = projectionMatrix
        
        let baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0, -8.0, -8.0)
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
            for i in 0...scrapObjects.count-1 {
                Physics.applyMagnetPull(playerMagnet: playerMagnet, objectToPull: &scrapObjects[i], magnetStrength: 1, pullRadius: 10)
            }
        }
        
        var magnetBox: HitBox = HitBox(left:-0.6, right:0.1, top:0.1, bottom:-1.2, front:1.2, back:-1.2);
        var junkHitBox: HitBox = HitBox(left:-0.5, right:0.5, top:0.5, bottom:-0.5, front:0.5, back:-0.5);
        var grinderHitBox: HitBox = HitBox(left:-0.5, right:0.5, top:0.5, bottom:-0.5, front:0.5, back:-0.5);
        
        //print(playerCube.velocity);
        //print("collision: ",HitBox.collisionHasOccured(firstPos: playerMagnet.position, firstBox: magnetBox, secondPos: playerCube.position, secondBox: junkHitBox));
        for i in 0...scrapObjects.count-1 {
            if(HitBox.collisionHasOccured(firstPos: playerMagnet.position, firstBox: magnetBox, secondPos: scrapObjects[i].position, secondBox: junkHitBox)&&blockActivated){
                var magnetVel = Vector4(x:0,y:0,z:0,w:0)
                Physics.calculateCollision(ui: &magnetVel, firstPos: playerMagnet.position, firstBox: magnetBox, vi: &scrapObjects[i].velocity, secondPos: scrapObjects[i].position, secondBox: junkHitBox, mass1: 1000, mass2: 1)
            }
        }
        
        // TODO: Loop through models to set their MVM's, then set their normals, then projection matrices
        
        //TODO: Set into objects. There is a better way of doing this
//        playerCube.addToVelocities(velx: 0, vely: Float(-9.81*self.timeSinceLastUpdate), velz: 0)
//        playerCube.updatePosition(deltaTime: GLfloat(self.timeSinceLastUpdate))
        //loop this for all scrap objects. 8==========D~~~~~~~ HANK LO ~~~~~~~~~~~~~
        if(scrapObjects[0].tag == "Scrap"){
            if(HitBox.collisionHasOccured(firstPos: scrapObjects[0].position, firstBox: junkHitBox, secondPos: grinderBox.position, secondBox: grinderHitBox)){
                scrapObjects[0].tag = "cleared";
                pp.setScore(score: pp.getScore() + 10000)
                self.endLevel()
            }
        }

        for i in 0...scrapObjects.count-1 {
            scrapObjects[i].addToVelocities(velx: 0, vely: Float(-9.81*self.timeSinceLastUpdate), velz: 0)
            scrapObjects[i].updatePosition(deltaTime: GLfloat(self.timeSinceLastUpdate))
        }
        
        
        for i in 0...scrapObjects.count-1 {
            var modelViewMatrix6 = scrapObjects[i].getTranslationMatrix()
            modelViewMatrix6 = GLKMatrix4Translate(modelViewMatrix6, 0, 2, 0)
            modelViewMatrix6 = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix6)
            normalMatrix6 = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix6), nil)
            modelViewProjectionMatrix6 = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix6)
            scrapObjects[i].modelViewMatrix = modelViewMatrix6
            scrapObjects[i].normalMatrix = normalMatrix6
            scrapObjects[i].modelViewProjectionMatrix = modelViewProjectionMatrix6
        }
        
        // TODO: Fix this so that there is a better way of doing it
        var modelViewMatrix = playerMagnet.getTranslationMatrix();
        var modelViewMatrix2 = playerCube.getTranslationMatrix();
        var modelViewMatrix3 = ground.getTranslationMatrix()
        var modelViewMatrix4 = grinderBox.getTranslationMatrix()
        var modelViewMatrix5 = grinderBlades.getTranslationMatrix()
        //var modelViewMatrix6 = scrapObjects[0].getTranslationMatrix()
        modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, 0.5, 0.5, 0.5)
        modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix)
        modelViewMatrix2 = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix2)
        modelViewMatrix3 = GLKMatrix4Scale(modelViewMatrix3, 1000, 0.5, 1000)
        modelViewMatrix3 = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix3)
        modelViewMatrix4 = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix4)
        modelViewMatrix5 = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix5)
        //modelViewMatrix6 = GLKMatrix4Translate(modelViewMatrix6, 0, 2, 0)
        //modelViewMatrix6 = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix6)
        
        normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), nil)
        normalMatrix2 = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix2), nil)
        normalMatrix4 = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix4), nil)
        normalMatrix5 = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix5), nil)
        //normalMatrix6 = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix6), nil)
        
        modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix)
        modelViewProjectionMatrix2 = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix2)
        modelViewProjectionMatrix3 = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix3)
        modelViewProjectionMatrix4 = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix4)
        modelViewProjectionMatrix5 = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix5)
        //modelViewProjectionMatrix6 = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix6)
        
        playerMagnet.modelViewMatrix = modelViewMatrix
        playerMagnet.normalMatrix = normalMatrix
        playerMagnet.modelViewProjectionMatrix = modelViewProjectionMatrix
        
        ground.modelViewMatrix = modelViewMatrix3
        ground.normalMatrix = normalMatrix3
        ground.modelViewProjectionMatrix = modelViewProjectionMatrix3
        
        grinderBox.modelViewMatrix = modelViewMatrix4
        grinderBox.normalMatrix = normalMatrix4
        grinderBox.modelViewProjectionMatrix = modelViewProjectionMatrix4
        
        grinderBlades.modelViewMatrix = modelViewMatrix5
        grinderBlades.normalMatrix = normalMatrix5
        grinderBlades.modelViewProjectionMatrix = modelViewProjectionMatrix5
        
        grinderBlades.modelViewMatrix = modelViewMatrix5
        grinderBlades.normalMatrix = normalMatrix5
        grinderBlades.modelViewProjectionMatrix = modelViewProjectionMatrix5
        
        //scrapObjects[0].modelViewMatrix = modelViewMatrix6
        //scrapObjects[0].normalMatrix = normalMatrix6
        //scrapObjects[0].modelViewProjectionMatrix = modelViewProjectionMatrix6
        
//        self.setObjectMVPMatrixPlayer(po: &playerMagnet, base: baseModelViewMatrix, proj: projectionMatrix, translate: Vector4(x: 0, y: 0, z: 0, w: 0), scale: Vector4(x: 0.5, y: 0.5, z: 0.5, w: 0))
//        self.setObjectMVPMatrix(go: &ground, base: baseModelViewMatrix, proj: projectionMatrix, translate: Vector4(x: 0, y: 0, z: 0, w: 0), scale: Vector4(x: 1000, y: 0.5, z: 1000, w: 0))
//        self.setObjectMVPMatrix(go: &grinderBox, base: baseModelViewMatrix, proj: projectionMatrix, translate: Vector4(x: 0, y: 0, z: 0, w: 0), scale: Vector4(x: 0, y: 0, z: 0, w: 0))
//        self.setObjectMVPMatrix(go: &grinderBlades, base: baseModelViewMatrix, proj: projectionMatrix, translate: Vector4(x: 0, y: 0, z: 0, w: 0), scale: Vector4(x: 0, y: 0, z: 0, w: 0))
        
        //rotation += Float(self.timeSinceLastUpdate * 0.5)
        self.updateTimer(dt: self.timeSinceLastUpdate)
        
        if(movingUp){
            playerMagnet.moveObject(xMove: 0.0, yMove: 0.0, zMove: -0.1);
        }
        if(movingDown){
            playerMagnet.moveObject(xMove: 0.0, yMove: 0.0, zMove: 0.1);
        }
        if(movingLeft){
            playerMagnet.moveObject(xMove: -0.1, yMove: 0.0, zMove: 0.0);
        }
        if(movingRight){
            playerMagnet.moveObject(xMove: 0.1, yMove: 0.0, zMove: 0.0);
        }
        
        NSLog("Score: %d", pp.getScore());
    }
    
    func setObjectMVPMatrix(go: inout GameObject, base: GLKMatrix4, proj: GLKMatrix4, translate: Vector4, scale: Vector4) {
        go.modelViewMatrix = go.getTranslationMatrix()
        go.modelViewMatrix = GLKMatrix4Translate(go.modelViewMatrix, translate.x, translate.y, translate.z)
        go.modelViewMatrix = GLKMatrix4Scale(go.modelViewMatrix, scale.x, scale.y, scale.z)
        go.modelViewMatrix = GLKMatrix4Multiply(base, go.modelViewMatrix)
        go.normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(go.modelViewMatrix), nil)
        go.modelViewProjectionMatrix = GLKMatrix4Multiply(proj, go.modelViewMatrix)
    }
    
    func setObjectMVPMatrixPlayer(po: inout PlayerObject, base: GLKMatrix4, proj: GLKMatrix4, translate: Vector4, scale: Vector4) {
        po.modelViewMatrix = po.getTranslationMatrix()
        po.modelViewMatrix = GLKMatrix4Translate(po.modelViewMatrix, translate.x, translate.y, translate.z)
        po.modelViewMatrix = GLKMatrix4Scale(po.modelViewMatrix, scale.x, scale.y, scale.z)
        po.modelViewMatrix = GLKMatrix4Multiply(base, po.modelViewMatrix)
        po.normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(po.modelViewMatrix), nil)
        po.modelViewProjectionMatrix = GLKMatrix4Multiply(proj, po.modelViewMatrix)
    }
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glClearColor(0.65, 0.65, 0.65, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT) | GLbitfield(GL_DEPTH_BUFFER_BIT))
        
        glUseProgram(program)
        
        self.drawObject(go: playerMagnet)
        self.drawObject(go: ground)
        self.drawObject(go: grinderBox)
        self.drawObject(go: grinderBlades)
        for i in 0...scrapObjects.count-1 {
            self.drawObject(go: scrapObjects[i])
        }
//        self.drawObjects(gos: scrapObjects)
        
//        glBindVertexArrayOES(playerMagnet.vertexArray)
//        
//        withUnsafePointer(to: &modelViewProjectionMatrix, {
//            $0.withMemoryRebound(to: Float.self, capacity: 16, {
//                glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, $0)
//            })
//        })
//        
//        withUnsafePointer(to: &normalMatrix, {
//            $0.withMemoryRebound(to: Float.self, capacity: 9, {
//                glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, $0)
//            })
//        })
//        
//        glDrawArrays(GLenum(GL_TRIANGLES), 0, GLsizei(playerMagnet.getObjectData().position.count))
        
//        glBindVertexArrayOES(playerCube.vertexArray)
//        
//        withUnsafePointer(to: &modelViewProjectionMatrix2, {
//            $0.withMemoryRebound(to: Float.self, capacity: 16, {
//                glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, $0)
//            })
//        })
//        
//        withUnsafePointer(to: &normalMatrix2, {
//            $0.withMemoryRebound(to: Float.self, capacity: 9, {
//                glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, $0)
//            })
//        })
//        
//        glDrawArrays(GLenum(GL_TRIANGLES), 0, GLsizei(playerCube.getObjectData().position.count))
//        
//        glBindVertexArrayOES(ground.vertexArray)
//        
//        withUnsafePointer(to: &modelViewProjectionMatrix3, {
//            $0.withMemoryRebound(to: Float.self, capacity: 16, {
//                glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, $0)
//            })
//        })
//        
//        withUnsafePointer(to: &normalMatrix3, {
//            $0.withMemoryRebound(to: Float.self, capacity: 9, {
//                glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, $0)
//            })
//        })
//        
//        glDrawArrays(GLenum(GL_TRIANGLES), 0, GLsizei(ground.getObjectData().position.count))
    }
    
    func drawObject(go: GameObject) {
        glBindVertexArrayOES(go.vertexArray)
        
        withUnsafePointer(to: &go.modelViewProjectionMatrix, {
            $0.withMemoryRebound(to: Float.self, capacity: 16, {
                glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, $0)
            })
        })
        
        withUnsafePointer(to: &go.normalMatrix, {
            $0.withMemoryRebound(to: Float.self, capacity: 9, {
                glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, $0)
            })
        })
        
        glDrawArrays(GLenum(GL_TRIANGLES), 0, GLsizei(go.getObjectData().position.count))
    }
    
    func drawObjects(gos: [GameObject]) {
        for go in gos {
            self.drawObject(go: go)
        }
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
