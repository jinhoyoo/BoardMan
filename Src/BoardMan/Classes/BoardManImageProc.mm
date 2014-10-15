//
//  BoardManImageProc.c
//  BoardMan
//
//  Created by 유진호 on 11. 1. 16..
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//


#include "BoardManImageProc.h"

#include <vector>
#include <list>
#include <iostream>

using namespace std;



unsigned char  normColor( unsigned char wb, unsigned char inp )
{
	if ( wb == 0 )
		return 0;

	double val ;
	
	double temp = double(inp)/double(wb);
	
	if( 1.0 > temp ) 
		val = temp; 
	else 
		val = 1.0;

	unsigned char cVal = (unsigned char)(val * 255.0);

	return cVal;
}



void CalMajorColor( const IplImage* pImg , CvScalar& MajorCol, float ratioOfMaxLuminance )
{
	
	CvSize size = cvGetSize( pImg );
	IplImage* grayIm = cvCreateImage( size, 8, 1 );
	
	cvCvtColor( pImg, grayIm, CV_BGR2GRAY );
	
	
	
	double minLum  = 0.0;
	double maxLum  = 0.0; 
	
	
	cvMinMaxLoc(grayIm, &minLum, &maxLum, NULL );
	
	
	double thr_lum = maxLum* ratioOfMaxLuminance;
	
	double sum_col[] = {0.0, 0.0, 0.0 };
	
	

	int nCatched = 0;
	

	for ( int idx =0 ; idx < ( pImg->width * pImg->height) ; ++idx ) 
	{
		
		unsigned char val = 
		(unsigned char)( grayIm->imageData[ idx  ] );

		if ( thr_lum <= val )
		{
			unsigned char*  pImgPtr = NULL;
			
			int nChannels = pImg->nChannels;

			pImgPtr = (unsigned char* )( pImg->imageData );
			
			pImgPtr = pImgPtr + nChannels * idx ;
			
			
			sum_col[0] += (double)( *(pImgPtr + 0) );
			sum_col[1] += (double)( *(pImgPtr + 1) );
			sum_col[2] += (double)( *(pImgPtr + 2) );
		
			nCatched++;
		}
		
		
		
	}	
	
	MajorCol.val[0] = sum_col[0] / double( nCatched );
	MajorCol.val[1] = sum_col[1] / double( nCatched );
	MajorCol.val[2] = sum_col[2] / double( nCatched );

	
}




void GetWhiteBoardImage( IplImage *src, int block_w, int block_h, float ratioOfMaxLuminance, 
						 IplImage  **trg, CvScalar board_color = CV_RGB(255, 255, 255)  )
{
	assert( ( *trg == NULL ) && "Target image should be null. It should be alloced in this function. "  );
	
	
	//영상크기를 전체적으로 1/4 크기로 줄이고 한다.
	//-----------------------------------------
	IplImage* imReduced = cvCreateImage(cvSize( src->width/10, src->height/10 ), 
										IPL_DEPTH_8U, 3 );
	
	cvResize(src, imReduced, CV_INTER_LINEAR );
	//-----------------------------------------
	
	
	//A. 1개 글자 크기 정도의 Cell로 나눈다. block_w, block_h의 배수가 되는 크기로 조절 
	//-----------------------------------------
	int newWidth  = (int)( (float)src->width  / (float)block_w  );
	newWidth = newWidth * block_w;
	
	int newHeight = (int)( (float)src->height / (float)block_h  );
	newHeight = newHeight * block_h;
		
	IplImage* imResized = cvCreateImage( cvSize( newWidth, newHeight ), 
										 src->depth, src->nChannels ); 
	
	cvResize( imReduced, imResized, CV_INTER_LINEAR );
	//-----------------------------------------

	

	
	//B. 밝기값으로 Cell내의 pixel을 정렬한다. White board색은 주로 높은 밝기 값을 가지는 color 
	//   값이다. Error를 줄이기 위해 상위 25% 내의 color를 평균내었다.
	std::list< CvPoint > block_pos;
	
	for (int y = 0; y < imResized->height;  y += block_h ) 
	{
		for (int x = 0; x < imResized->width; x += block_w ) 
		{
			block_pos.push_back(  cvPoint(x, y)  );
		}
		
	}
	
	IplImage* tmpCol = cvCreateImage( cvSize( block_w, block_h), 
									 src->depth, src->nChannels );
	
	IplImage* imWBBack = cvCloneImage( imResized );
	cvSet( imWBBack, board_color  ); //보드가 화이트 보드라고 가정 
	
	
	
	
	list< CvPoint >::iterator iter;
	

	IplImage* tmpImg = cvCreateImage(cvSize( block_w, block_h ), 8, 3 );
	
	
	
	
	for (  iter = block_pos.begin() ; iter != block_pos.end() ; iter++ ) 
	{
		CvScalar rgbCol; 
		
		CvRect rect =	cvRect( (*iter).x, (*iter).y, block_w, block_h)  ;
		
		cvSetImageROI(imResized, rect );
		cvCopy(imResized, tmpImg );
		cvResetImageROI( imResized );
		
		
		CalMajorColor( tmpImg, rgbCol, ratioOfMaxLuminance );
		
		
		CvPoint pt1 = cvPoint( (*iter).x, (*iter).y );
		CvPoint pt2 = cvPoint( (*iter).x + block_w-1, (*iter).y + block_h-1 );
		
		cvRectangle( imWBBack, pt1, pt2, rgbCol,  CV_FILLED );
	
		
		
	}
	
	*trg = cvCreateImage( cvGetSize( src ), 8, 3 );
	cvResize(imWBBack, *trg, CV_INTER_CUBIC );
	
	
	
	
	cvReleaseImage( &tmpImg );
	
	
	cvReleaseImage( &tmpCol	   );
	cvReleaseImage( &imWBBack  );
	cvReleaseImage( &imReduced );
	cvReleaseImage( &imResized );
	
	
	
}



#pragma mark OpenCV Support Methods

bool EnhanceBoardImage(	IplImage *pSrc,  IplImage *pTrg, 
						int block_w, int block_h , float ratioOfMaxLuminance )
{
	
	
	
	//Check arguments.
	IplImage* imWhiteBd = NULL;
	
	
	
	//White board 색 추출한 image생성. 
	GetWhiteBoardImage( pSrc, block_w, block_h, ratioOfMaxLuminance, &imWhiteBd ); 

	NSLog(@"Finish estimating whiteboard color...\n");

	
	//Color refine작업
	//----------------------------------------
	int nElem = imWhiteBd->width * imWhiteBd->height;
	
	unsigned char pixRes[3];
	
	
	
	
	for ( int idx = 0; idx< nElem; ++idx) 
	{
		unsigned char* pixAPtr = NULL;
		unsigned char* pixBPtr = NULL;
		
		int nChannels = imWhiteBd->nChannels;
		
		pixAPtr = 
			(unsigned char*)( imWhiteBd->imageData );
		
		pixBPtr = 
			(unsigned char*)( pSrc->imageData );
		
		unsigned char* pixResPtr
			= (unsigned char* ) (  pTrg->imageData  );
		
		
		pixAPtr = pixAPtr + idx * nChannels;
		
		pixBPtr = pixBPtr + idx * nChannels;
		
		pixResPtr = pixResPtr + idx * nChannels;
		
		
		pixRes[0] =
			normColor( *pixAPtr, *pixBPtr );
		
		pixRes[1] = 
			normColor( *( pixAPtr + 1), *( pixBPtr + 1) );
		
		pixRes[2] = 
			normColor( *( pixAPtr + 2), *( pixBPtr + 2) );
		
		
		
		
		(*pixResPtr )		   = pixRes[0];
		(*( pixResPtr + 1 ) )  = pixRes[1];
		(*( pixResPtr + 2 ) )  = pixRes[2];
		
		
	}
	

	
	//----------------------------------------
	
	
	cvReleaseImage( &imWhiteBd );
	
	cvCvtColor( pTrg, pTrg, CV_BGR2RGB );
	
	return true;
	
}


bool InvertImage( IplImage *pSrc, IplImage *pTrg )
{
	if( NULL == pSrc )
		return false;
	
	if( NULL == pTrg )
		return false;
	
	IplImage* pTmp = cvCloneImage(pSrc);
	
	
	cvSet( pTmp, cvScalar( 255.0, 255.0, 255.0, 255.0 ), NULL );
	
	cvSub(pTmp, pSrc, pTrg, NULL );
	
	cvReleaseImage( &pTmp );
	
	return true;	
	
}

