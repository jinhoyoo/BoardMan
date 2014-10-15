#! /usr/bin/env python
# -*- coding: utf-8 -*-
#
#  Algorithm1.py
#  
#
#  Created by 유진호 on 09. 07. 03.
#  Copyright (c) 2009 __MyCompanyName__. All rights reserved.
#

from opencv.cv import *
from opencv.highgui import *
from opencv.matlab_syntax import *



def resizeImgForStepWalk( block_w, block_h, grayImg ):

	width  = block_w * ( grayImg.width / block_w )
	height = block_h * ( grayImg.height / block_h )
	

	grayImg2 = cvCreateImage( cvSize( width, height) , 8, 1)
	
	cvResize( grayImg, grayImg2, CV_INTER_CUBIC )
		
	return grayImg2

#end def

def copyTrgToSrc( x, y,  subImg, src ):
	
	for i in range( subImg.width ):
		for j in range(  subImg.height ):
			src[ y+j ][ x+i ] = subImg[ j ][ i ]

#end def



if __name__ == "__main__":
	
	storage = cvCreateMemStorage(0)
	
	filename = 'BoardTest4.jpg'
	block_w = 20
	block_h = 20

	im = imread( filename )
	grayImg = cvCreateImage( cvGetSize( im ), 8, 1)
	cvCvtColor( im, grayImg, CV_BGR2GRAY )

	grayImg2 = resizeImgForStepWalk( block_w, block_h, grayImg )
	trgImg = cvCloneImage( grayImg2 ) 
		
	
	cvSaveImage( "result.bmp", trgImg )
	
	cvClearMemStorage( storage )
