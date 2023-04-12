//=====================================================================================
// Common structs, parameters, functions
// Original: https://github.com/databio/aiarray/tree/master/src
// by Kyle S. Smith and Jianglin Feng
//-------------------------------------------------------------------------------------
#ifndef __INTERVAL_H__
#define __INTERVAL_H__
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <ctype.h>
#include <math.h>
#include <assert.h>

//-------------------------------------------------------------------------------------

typedef struct {
    uint32_t start;      				// Region start: 0-based
    uint32_t end;    					// Region end: not inclusive
    int32_t id_value;					// Region ID
} interval_t;

//-------------------------------------------------------------------------------------
// interval.c
//=====================================================================================

// Initialize interval_t
interval_t *interval_init(uint32_t start, uint32_t end, int32_t id_value);

#endif
