#ifndef ASTRO_LOGIC_ASTRONOMY_H
#define ASTRO_LOGIC_ASTRONOMY_H

#if defined(_WIN32)
#define AL_API __declspec(dllexport)
#else
#define AL_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

enum al_body {
    AL_BODY_SUN = 0,
    AL_BODY_MOON = 1,
    AL_BODY_MARS = 2,
    AL_BODY_MERCURY = 3,
    AL_BODY_JUPITER = 4,
    AL_BODY_VENUS = 5,
    AL_BODY_SATURN = 6,
    AL_BODY_URANUS = 7,
    AL_BODY_NEPTUNE = 8,
    AL_BODY_PLUTO = 9
};

typedef struct al_position {
    int status;
    double tropical_longitude;
    double ecliptic_latitude;
    double longitude_speed_per_day;
} al_position;


typedef struct al_kp_frame {
    int status;
    int placidus_status;
    double krishnamurti_ayanamsha;
    double tropical_ascendant;
    double tropical_mc;
    double sidereal_ascendant;
    double sidereal_mc;
    double true_node_tropical;
    double mean_node_tropical;
    double tropical_cusps[12];
    double sidereal_cusps[12];
} al_kp_frame;


typedef struct al_western_frame {
    int status;
    int placidus_status;
    double tropical_ascendant;
    double tropical_mc;
    double true_node_tropical;
    double mean_node_tropical;
    double tropical_cusps[12];
} al_western_frame;

typedef struct al_frame_supplement {
    int status;
    double lahiri_ayanamsha;
    double tropical_ascendant;
    double true_node_longitude;
    double true_node_speed_per_day;
    double mean_node_longitude;
    double mean_node_speed_per_day;
    double sun_hour_angle_hours;
    int tribhaga_status;
    int tribhaga_is_day;
    int tribhaga_third;
    double tribhaga_period_start_offset_days;
    double tribhaga_period_end_offset_days;
    int astrological_day_status;
    double astrological_day_start_offset_days;
    int solar_ingress_status;
    double varsha_ingress_offset_days;
    double varsha_day_start_offset_days;
    double masa_ingress_offset_days;
    double masa_day_start_offset_days;
} al_frame_supplement;

AL_API const char *al_astronomy_engine_version(void);

AL_API al_position al_geocentric_position(
    int body,
    int year,
    int month,
    int day,
    int hour,
    int minute,
    double second
);


AL_API al_kp_frame al_calculate_kp_frame(
    int year,
    int month,
    int day,
    int hour,
    int minute,
    double second,
    double latitude,
    double longitude
);


AL_API al_western_frame al_calculate_western_frame(
    int year,
    int month,
    int day,
    int hour,
    int minute,
    double second,
    double latitude,
    double longitude
);

AL_API al_frame_supplement al_calculate_frame_supplement(
    int year,
    int month,
    int day,
    int hour,
    int minute,
    double second,
    double latitude,
    double longitude
);

#ifdef __cplusplus
}
#endif

#endif
