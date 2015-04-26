//
//  get_time_monotonic.h
//  Safe
//
//  Created by Chuck Musser on 3/20/15.
//  Copyright (c) 2015 Chuck Musser. All rights reserved.
//

#ifndef __Safe__get_time_monotonic__
#define __Safe__get_time_monotonic__

#include <stdio.h>

struct timespec orwl_gettime(void);
int delta_below_threshold(struct timespec start, struct timespec end, int threshold);

#endif /* defined(__Safe__get_time_monotonic__) */
