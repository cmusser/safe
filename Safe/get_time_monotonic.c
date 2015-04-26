//
//  get_time_monotonic.c
//  Safe
//
//  http://stackoverflow.com/questions/5167269/clock-gettime-alternative-in-mac-os-x
//
#include <mach/mach_time.h>

#include "get_time_monotonic.h"

#define ORWL_NANO (+1.0E-9)
#define ORWL_GIGA UINT64_C(1000000000)

static double orwl_timebase = 0.0;
static uint64_t orwl_timestart = 0;

struct timespec orwl_gettime(void) {
    // be more careful in a multithreaded environement
    if (!orwl_timestart) {
        mach_timebase_info_data_t tb = { 0 };
        mach_timebase_info(&tb);
        orwl_timebase = tb.numer;
        orwl_timebase /= tb.denom;
        orwl_timestart = mach_absolute_time();
    }
    struct timespec t;
    double diff = (mach_absolute_time() - orwl_timestart) * orwl_timebase;
    t.tv_sec = diff * ORWL_NANO;
    t.tv_nsec = diff - (t.tv_sec * ORWL_GIGA);
    return t;
}

int delta_below_threshold(struct timespec start, struct timespec end, int threshold)
{
    struct timespec delta;

    delta.tv_sec = end.tv_sec - start.tv_sec;
    delta.tv_nsec = end.tv_nsec - start.tv_nsec;

//    return ((delta.tv_sec == 0 && delta.tv_nsec <= threshold)) ? 1 : 0;
    return (delta.tv_sec <= threshold) ? 1 : 0;
}