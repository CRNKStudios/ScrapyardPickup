//
//  Shader.fsh
//  ScrapyardPickup
//
//  Created by Spencer Pollock on 2017-02-15.
//  Copyright © 2017 CRNK Studios. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
