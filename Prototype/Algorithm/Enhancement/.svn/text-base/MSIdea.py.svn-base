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



def resizeImgForStepWalk( w, h, Img ):

	width  = block_w * ( Img.width / w )
	height = block_h * ( Img.height / h )
	
	Img2 = cvCreateImage( cvSize( width, height) , Img.depth,  Img.nChannels )
	
	cvResize( Img, Img2, CV_INTER_CUBIC )
		
	return Img2

#end def

def copyTrgToSrc( x, y,  subImg, src ):
	
	for i in range( subImg.width ):
		for j in range(  subImg.height ):
			src[ y+j ][ x+i ] = subImg[ j ][ i ]

#end def


def CalMajorColor( img ):

	grayIm = cvCreateImage( cvGetSize( img ), 8, 1)
	cvCvtColor( img, grayIm, CV_BGR2GRAY )
	
	minLum  = 0
	maxLum  = 0
	result = cvMinMaxLoc( grayIm, 0 )
	maxLum = result[1]
	
	thr_Lum = int ( float(maxLum) * 0.75 )
		
	sum_col = [0, 0, 0]
	num_catched = 0
	for x in range( img.width ):
		for y in range( img.height ):
		
			if  thr_Lum <= grayIm[y][x] :
				sum_col[0] += img[y][x][0] 
				sum_col[1] += img[y][x][1] 
				sum_col[2] += img[y][x][2] 
				num_catched += 1 
			
		#end for
	#end for
	
	b = int( sum_col[0]/num_catched  )
	g = int( sum_col[1]/num_catched  )
	r = int( sum_col[2]/num_catched  )
	return r, g, b
	

#end def

def getWhiteBoardImage( im, block_w, block_h ):
	#-영상크기를 전체적으로 1/4 크기로 줄이고 한다. 
	imReduced = cvCreateImage( cvSize( im.width/4, im.height/4) , 8, 3)
	cvResize( im, imReduced, CV_INTER_CUBIC )

	
	#A. 1개 글자 크기 정도의 Cell로 나눈다. ( 보통 15x15라는데... ) 
	imResized = resizeImgForStepWalk( block_w, block_h, imReduced)

	
	#B. 밝기값으로 Cell내의 pixel을 정렬한다. White board색은 주로 높은 밝기 값을 가지는 color 
	#   값이다. Error를 줄이기 위해 상위 25% 내의 color를 평균내었다. 
	block_pos = [  ]
	for x in range( 0, imResized.width, block_w ):
		for y in range( 0, imResized.height, block_h):
			
			block_pos.append( [x, y] )
		#end for
	#end for
	
	tmpCol = cvCreateImage( cvSize( block_w, block_h), 8, 3 )
	
	imWBBack = cvCloneImage( imResized )
	
	cvSet( imWBBack, CV_RGB( 255, 255, 255 ) )
	
	block_col = [  ]
	for block in block_pos:
	
		tmpImg = cvGetSubRect( imResized, \
		 cvRect( block[0], block[1], block_w, block_h ) )
		
		rgbCol = CalMajorColor( tmpImg )
		
		pt1 = cvPoint( block[0], block[1] )
		pt2 = cvPoint( block[0] + block_w, block[1] + block_h )
		
		cvRectangle( imWBBack, pt1, pt2, \
		CV_RGB( rgbCol[0], rgbCol[1], rgbCol[2] ), CV_FILLED )
		
		block_col.append( rgbCol );
	
	#end for
	
	#1/4축소한 이미지를 4배 확대한다. 
	imWhiteBoard = cvCreateImage( cvSize( im.width, im.height) , 8, 3)
	cvResize( imWBBack, imWhiteBoard, CV_INTER_CUBIC )

	return imWhiteBoard
#end def


def normColor( wb, inp ):
	if wb == 0:
		return 0
	
	val = min( 1.0, float(inp)/float(wb) )
	
	val = int(val * 255.0)
	
	return val
#end def


#end def 

if __name__ == "__main__":
	
	storage = cvCreateMemStorage(0)
	
	filename = 'BoardTest4.jpg'

	im = imread( filename )
	
	block_w = 10
	block_h = 10 
	# White board 색 추출하기 
	imWhiteBd = getWhiteBoardImage( im, block_w, block_h )
	
	imResult = cvCreateImage( cvSize( im.width, im.height) , 8, 3)
	cvSaveImage(  "wb_image.bmp", imWhiteBd )
	#cvSet( imResult, CV_RGB( 255, 255, 255 ) )

	#color refine하기
	for x in range( 0, im.width ):
		for y in range( 0, im.height):
			
			r = normColor( imWhiteBd[y][x][0], im[y][x][0] )
			g = normColor( imWhiteBd[y][x][1], im[y][x][1] )
			b = normColor( imWhiteBd[y][x][2], im[y][x][2] )
			
			imResult[y][x] = CV_RGB( b, g, r)
			
			#print imResult[y][x][0], imResult[y][x][1], imResult[y][x][2]


			
		#end for
	#end for 
	

	cvSaveImage(  "result_image.bmp", imResult )
	#print block_pos
	#print block_col
					
	
	cvClearMemStorage( storage )
