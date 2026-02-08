/***************************************************************************
 *   CPU Governor control for Miyoo Mini / OnionOS                         *
 *   Allows dynamic frequency scaling for performance boost                *
 ***************************************************************************/

#ifndef CPU_GOVERNOR_H
#define CPU_GOVERNOR_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/* CPU frequency scaling for Miyoo Mini 
 * Default: 1200 MHz
 * Boost: 1500 MHz (for demanding scenes)
 */

#define CPU_FREQ_DEFAULT 1200000
#define CPU_FREQ_BOOST   1500000

/* Sysfs paths for CPU governor control */
#define CPU_FREQ_PATH "/sys/devices/system/cpu/cpu0/cpufreq/scaling_setspeed"
#define CPU_GOV_PATH  "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"

static int cpu_governor_available = 0;
static int cpu_freq_boosted = 0;

/* Initialize CPU governor control */
static inline int cpu_governor_init(void)
{
    FILE *f;
    
    /* Check if governor control is available */
    f = fopen(CPU_GOV_PATH, "r");
    if (f)
    {
        cpu_governor_available = 1;
        fclose(f);
        
        /* Set governor to userspace for manual control */
        f = fopen(CPU_GOV_PATH, "w");
        if (f)
        {
            fprintf(f, "userspace\n");
            fclose(f);
        }
        
        /* Set to default frequency */
        if (!cpu_governor_set_freq(CPU_FREQ_DEFAULT))
        {
            /* Failed to set frequency - log warning but continue */
            /* In production, this would use gambatte_log() */
            cpu_governor_available = 0;
            return 0;
        }
        
        return 1;
    }
    
    cpu_governor_available = 0;
    return 0;
}

/* Set CPU frequency */
static inline int cpu_governor_set_freq(int freq_khz)
{
    FILE *f;
    
    if (!cpu_governor_available)
        return 0;
    
    f = fopen(CPU_FREQ_PATH, "w");
    if (!f)
        return 0;
    
    fprintf(f, "%d\n", freq_khz);
    fclose(f);
    
    return 1;
}

/* Boost CPU frequency for demanding scenes */
static inline void cpu_governor_boost(void)
{
    if (cpu_governor_available && !cpu_freq_boosted)
    {
        cpu_governor_set_freq(CPU_FREQ_BOOST);
        cpu_freq_boosted = 1;
    }
}

/* Return CPU to default frequency */
static inline void cpu_governor_unboost(void)
{
    if (cpu_governor_available && cpu_freq_boosted)
    {
        cpu_governor_set_freq(CPU_FREQ_DEFAULT);
        cpu_freq_boosted = 0;
    }
}

/* Dynamic boost based on frame time
 * If frame took too long, boost CPU for next few frames
 */
static unsigned int boost_counter = 0;
#define BOOST_FRAMES 10  /* Keep boost for 10 frames after slowdown */

static inline void cpu_governor_dynamic_boost(int frame_late)
{
    if (!cpu_governor_available)
        return;
    
    if (frame_late)
    {
        /* Frame was late, boost CPU */
        cpu_governor_boost();
        boost_counter = BOOST_FRAMES;
    }
    else if (boost_counter > 0)
    {
        /* Keep boost active for a few more frames */
        boost_counter--;
        if (boost_counter == 0)
            cpu_governor_unboost();
    }
}

/* Cleanup on exit */
static inline void cpu_governor_deinit(void)
{
    if (cpu_governor_available)
    {
        /* Return to default frequency */
        cpu_governor_unboost();
        
        /* Set governor back to ondemand/schedutil */
        FILE *f = fopen(CPU_GOV_PATH, "w");
        if (f)
        {
            fprintf(f, "ondemand\n");
            fclose(f);
        }
    }
}

#ifdef __cplusplus
}
#endif

#endif /* CPU_GOVERNOR_H */
