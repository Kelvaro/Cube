//
//  Copyright © 2017 Borna Noureddin. All rights reserved.
//

#import "Renderer.h"
#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#include <chrono>
#include "GLESRenderer.hpp"

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    UNIFORM_PASSTHROUGH,
    UNIFORM_SHADEINFRAG,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    NUM_ATTRIBUTES
};

@interface Renderer () {
    GLKView *theView;
    GLESRenderer glesRenderer;
    GLuint programObject;
    std::chrono::time_point<std::chrono::steady_clock> lastTime;

    GLKMatrix4 mvp;
    GLKMatrix3 normalMatrix;

    
    float scale;
    float lastscale;
    float _scaleStart;
    float _scaleEnd;
    float x;
    float y;
    float xp;
    float yp;
    float rotAngle;
    char isRotating;
    bool Toggle;
    float *vertices, *normals, *texCoords;
    int *indices, numIndices;
}

@end

@implementation Renderer

- (void)dealloc
{
    glDeleteProgram(programObject);
}

- (void)loadModels
{
    numIndices = glesRenderer.GenCube(1.0f, &vertices, &normals, &texCoords, &indices);
}

- (void)setup:(GLKView *)view
{
    view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    scale = 1.0;
    lastscale = 1.0;
    xp = 0.0;
    yp = 0.0;
    if (!view.context) {
        NSLog(@"Failed to create ES context");
    }
    Toggle = false;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    theView = view;
    [EAGLContext setCurrentContext:view.context];
    if (![self setupShaders])
        return;
    rotAngle = 0.0f;
    isRotating = 1;

    glClearColor ( 0.0f, 0.0f, 0.0f, 0.0f );
    glEnable(GL_DEPTH_TEST);
    lastTime = std::chrono::steady_clock::now();
}

- (void)update
{
    auto currentTime = std::chrono::steady_clock::now();
    auto elapsedTime = std::chrono::duration_cast<std::chrono::milliseconds>(currentTime - lastTime).count();
    lastTime = currentTime;
    
    if (Toggle == true)
    {
        rotAngle += 0.001f * elapsedTime;
        if (rotAngle >= 360.0f)
            rotAngle = 0.0f;
    }

 
    // Perspective
    mvp = GLKMatrix4Translate(GLKMatrix4Identity, xp, -yp, -5.0);
   // mvp = GLKMatrix4Translate(GLKMatrix4Identity, 0.0, 0.0, -5.0);
  
    mvp = GLKMatrix4Rotate(mvp, rotAngle, 1.0, 0.0, 0.0 );
    mvp = GLKMatrix4Rotate(mvp, x, 0.0, 1.0, 0.0);
    mvp = GLKMatrix4Rotate(mvp, y, 1.0, 0.0, 0.0);
    mvp = GLKMatrix4Scale(mvp, 0.4 * scale, 0.4 * scale, 0.4 * scale);
    normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(mvp), NULL);
   // mvp = GLKMatrix4Scale(mvp, _scaleEnd, _scaleEnd, _scaleEnd);
    float aspect = (float)theView.drawableWidth / (float)theView.drawableHeight;
    GLKMatrix4 perspective = GLKMatrix4MakePerspective(60.0f * M_PI / 180.0f, aspect, 1.0f, 20.0f);

    mvp = GLKMatrix4Multiply(perspective, mvp);
}


-(void)toggle {
    
    Toggle =!Toggle;
    
}


-(void)rotate:(UIPanGestureRecognizer *)sender {
    CGPoint translation = [sender translationInView:sender.view];
    if(Toggle == false){
        
        
        if(sender.numberOfTouches == 1){
        NSLog(@"this method is being called");
        
        x =  translation.x/sender.view.frame.size.width;
        y =  translation.y/sender.view.frame.size.height;
     
    }
   if(sender.numberOfTouches == 2){
       
       NSLog(@"this double touch condition is being recognized");
       xp = translation.x/sender.view.frame.size.width;
       yp = translation.y/sender.view.frame.size.height;
       
   }
        
    }
    
    
    
}
-(void)reset:(UIButton *)sender {
    NSLog(@"this button is pressed");
    x = 0.0;
    y = 0.0;
    scale =  1.0;
    Toggle = false;
    xp = 0.0;
    yp = 0.0;
    
}

- (void)pinch:(UIPinchGestureRecognizer*)sender{
    NSLog(@"Scale %.1f", scale);
    
    if(Toggle == false){
    if([(UIPinchGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded){
       
        scale = scale - (lastscale - sender.scale);
        lastscale = sender.scale;
  
        }
    }
}

- (void)Xpos:(UITextField *)sender{
    
    
    
}
- (void)draw:(CGRect)drawRect;
{
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, FALSE, (const float *)mvp.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, normalMatrix.m);
    glUniform1i(uniforms[UNIFORM_PASSTHROUGH], false);
    glUniform1i(uniforms[UNIFORM_SHADEINFRAG], true);

    glViewport(0, 0, (int)theView.drawableWidth, (int)theView.drawableHeight);
    glClear ( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    glUseProgram ( programObject );

    glVertexAttribPointer ( 0, 3, GL_FLOAT,
                           GL_FALSE, 3 * sizeof ( GLfloat ), vertices );
    glEnableVertexAttribArray ( 0 );
    glVertexAttrib4f ( 1, 1.0f, 0.0f, 0.0f, 1.0f );
    glVertexAttribPointer ( 2, 3, GL_FLOAT,
                           GL_FALSE, 3 * sizeof ( GLfloat ), normals );
    glEnableVertexAttribArray ( 2 );
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, FALSE, (const float *)mvp.m);
    glDrawElements ( GL_TRIANGLES, numIndices, GL_UNSIGNED_INT, indices );
}


- (bool)setupShaders
{
    // Load shaders
    char *vShaderStr = glesRenderer.LoadShaderFile([[[NSBundle mainBundle] pathForResource:[[NSString stringWithUTF8String:"Shader.vsh"] stringByDeletingPathExtension] ofType:[[NSString stringWithUTF8String:"Shader.vsh"] pathExtension]] cStringUsingEncoding:1]);
    char *fShaderStr = glesRenderer.LoadShaderFile([[[NSBundle mainBundle] pathForResource:[[NSString stringWithUTF8String:"Shader.fsh"] stringByDeletingPathExtension] ofType:[[NSString stringWithUTF8String:"Shader.fsh"] pathExtension]] cStringUsingEncoding:1]);
    programObject = glesRenderer.LoadProgram(vShaderStr, fShaderStr);
    if (programObject == 0)
        return false;
    
    // Set up uniform variables
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(programObject, "modelViewProjectionMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(programObject, "normalMatrix");
    uniforms[UNIFORM_PASSTHROUGH] = glGetUniformLocation(programObject, "passThrough");
    uniforms[UNIFORM_SHADEINFRAG] = glGetUniformLocation(programObject, "shadeInFrag");

    return true;
}

@end

