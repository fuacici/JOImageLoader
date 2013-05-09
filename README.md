JOImageLoader
=============

UIImage Additions (With cache and request management included)
Usage: 
  
  first, set a loader for all UIImageView
      
    _imageLoader = [[JOImageLoader alloc] init];
    [UIImageView setImageLoader: _imageLoader];
        
  then, 
  
    UIImageView * v = nil;
    [v setImageWithUrlString: @"http://www.test.com/test.jpg"];

  or:
    
    [v setImageWithUrlString: urlstring placeHolder:nil animate:NO indicator:NO]
