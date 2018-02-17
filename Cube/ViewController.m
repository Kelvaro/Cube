//
//  ViewController.m
//  c8051intro3
//
//  Created by Borna Noureddin on 2017-12-20.
//  Copyright © 2017 Borna Noureddin. All rights reserved.
//

#import "ViewController.h"

@interface ViewController() {
    Renderer *glesRenderer; // ###
}
@end


@implementation ViewController

-(void) addGestureRecognizers {
    
    UITapGestureRecognizer *doubletapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubletapRecognized:)];
    [doubletapRecognizer setNumberOfTapsRequired:2];
    [self.view addGestureRecognizer:(doubletapRecognizer)];
    
}

-(IBAction) doubletapRecognized:(UITapGestureRecognizer*) recognizer{
    if(recognizer.state == UIGestureRecognizerStateRecognized){
        
        NSLog(@"double tap is working");
        [glesRenderer toggle];
        
    }
}

- (IBAction)panRotate:(UIPanGestureRecognizer *)sender {
    
    NSLog(@"Panning recongized");
    [glesRenderer rotate:(UIPanGestureRecognizer*)sender];
    
}

- (IBAction)pinchScale:(UIPinchGestureRecognizer *)sender {
    [glesRenderer pinch:(UIPinchGestureRecognizer*)sender];
    NSLog(@"pinch is being recognized here!");
    
}
- (IBAction)displayX:(UITextField *)sender {
    [glesRenderer Xpos:(UITextField *)sender];
    
}

- (IBAction)reset:(UIButton *)sender {
    
    [glesRenderer reset:(UIButton *)sender];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    // ### <<<
    glesRenderer = [[Renderer alloc] init];
    GLKView *view = (GLKView *)self.view;
    [glesRenderer setup:view];
    [glesRenderer loadModels];
    [self addGestureRecognizers];
    // ### >>>
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)update
{
    [glesRenderer update]; // ###
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [glesRenderer draw:rect]; // ###
}


@end
