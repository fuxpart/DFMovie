//
//  DFMovieDefine.h
//  DFMovie
//
//  Created by fuxp on 16/3/12.
//  Copyright © 2016年 fuxp. All rights reserved.
//

#ifndef DFMovieDefine_h
#define DFMovieDefine_h

typedef double DFMovieTime;

typedef NS_ENUM(NSInteger, DFMovieFillMode) {
    DFMovieFillModeResizeAspect,
    DFMovieFillModeResizeAspectFill,
    DFMovieFillModeResize
};

static inline double df_system_version() {
    return [UIDevice currentDevice].systemVersion.doubleValue;
}

#endif /* DFMovieDefine_h */
