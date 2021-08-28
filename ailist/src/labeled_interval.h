//=====================================================================================
// Common structs, parameters, functions
// Original: https://github.com/databio/aiarray/tree/master/src
// by Kyle S. Smith and Jianglin Feng
//-------------------------------------------------------------------------------------
#ifndef __LABELED_INTERVAL_H__
#define __LABELED_INTERVAL_H__
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
	uint16_t label;						// Region label
} labeled_interval_t;

//-------------------------------------------------------------------------------------
// labeled_interval.c
//=====================================================================================

// Initialize interval_t
labeled_interval_t *labeled_interval_init(uint32_t start, uint32_t end, int32_t id_value, uint16_t label);

#endif
