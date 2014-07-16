JOImageLoader
=============

UIImage Additions (With cache and request management included)
###Features:

  * Load image from Internet with NSURLConnection.
  * Cache image locally into disk, **BUT NO Cache** policy support so far,(No expiration mechanism, once cached never refreshed).
  * Efficient image decoding based on extra gcd queue to predecode. 
  
###Usage: 
  
  first, set a loader for all UIImageView
      
    _imageLoader = [[JOImageLoader alloc] init];
    [UIImageView setImageLoader: _imageLoader];
        
  then: 
  
    UIImageView * v = nil;
    [v setImageWithUrlString: @"http://www.test.com/test.jpg"];

  or,
    
    [v setImageWithUrlString: urlstring placeHolder:nil animate:NO indicator:NO]
    
###Todo:

  * Add support for cache control.(etag, Expires, if-not-modified,etc)

###Notes for me:
  * only save origin image into disk even if called with downscalation.
  * 
