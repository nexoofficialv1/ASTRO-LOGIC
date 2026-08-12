#include "astro_logic_astronomy.h"

#include <math.h>

#include "../third_party/astronomy_engine/astronomy.h"

#define SPEED_SAMPLE_DAYS (1.0 / 24.0)
#define AL_RAD2DEG (180.0 / 3.14159265358979323846)
#define SPICA_J2000_RA_HOURS 13.41988333
#define SPICA_J2000_DEC_DEGREES (-11.16131944)
#define SPICA_DISTANCE_LIGHT_YEARS 250.0
#define AL_DEG2RAD (3.14159265358979323846 / 180.0)
#define AL_J2000 2451545.0
#define AL_J1900 2415020.0
#define AL_B1850 2396758.2035810
#define KP_CLASSIC_AYAN_J1900 (360.0 - 337.636111)
#define KP_VALID_START_JD 2393105.5
#define KP_VALID_END_JD 2488434.5

static astro_body_t map_body(int body)
{
    switch (body) {
        case AL_BODY_SUN: return BODY_SUN;
        case AL_BODY_MOON: return BODY_MOON;
        case AL_BODY_MARS: return BODY_MARS;
        case AL_BODY_MERCURY: return BODY_MERCURY;
        case AL_BODY_JUPITER: return BODY_JUPITER;
        case AL_BODY_VENUS: return BODY_VENUS;
        case AL_BODY_SATURN: return BODY_SATURN;
        case AL_BODY_URANUS: return BODY_URANUS;
        case AL_BODY_NEPTUNE: return BODY_NEPTUNE;
        case AL_BODY_PLUTO: return BODY_PLUTO;
        default: return BODY_INVALID;
    }
}

static astro_angle_result_t longitude_at(astro_body_t body, astro_time_t time)
{
    astro_vector_t vector = Astronomy_GeoVector(body, time, ABERRATION);
    astro_ecliptic_t ecliptic;
    astro_angle_result_t result;

    result.status = vector.status;
    result.angle = NAN;
    if (vector.status != ASTRO_SUCCESS)
        return result;

    ecliptic = Astronomy_Ecliptic(vector);
    result.status = ecliptic.status;
    if (ecliptic.status == ASTRO_SUCCESS)
        result.angle = ecliptic.elon;
    return result;
}

static double signed_angle_difference(double later, double earlier)
{
    double difference = fmod(later - earlier + 540.0, 360.0) - 180.0;
    return difference;
}

static double normalize_degrees(double angle)
{
    double result = fmod(angle, 360.0);
    return result < 0.0 ? result + 360.0 : result;
}

static astro_angle_result_t lahiri_ayanamsha(astro_time_t time)
{
    astro_angle_result_t spica;
    spica.status = Astronomy_DefineStar(
        BODY_STAR1,
        SPICA_J2000_RA_HOURS,
        SPICA_J2000_DEC_DEGREES,
        SPICA_DISTANCE_LIGHT_YEARS);
    spica.angle = NAN;
    if (spica.status != ASTRO_SUCCESS)
        return spica;
    spica = longitude_at(BODY_STAR1, time);
    if (spica.status == ASTRO_SUCCESS)
        spica.angle = normalize_degrees(spica.angle - 180.0);
    return spica;
}

static astro_angle_result_t true_lunar_node(astro_time_t time)
{
    astro_state_vector_t moon = Astronomy_GeoMoonState(time);
    astro_rotation_t rotation;
    astro_angle_result_t result;
    double hx, hy;

    result.status = moon.status;
    result.angle = NAN;
    if (moon.status != ASTRO_SUCCESS)
        return result;
    rotation = Astronomy_Rotation_EQJ_ECT(&time);
    if (rotation.status != ASTRO_SUCCESS) {
        result.status = rotation.status;
        return result;
    }
    moon = Astronomy_RotateState(rotation, moon);
    if (moon.status != ASTRO_SUCCESS) {
        result.status = moon.status;
        return result;
    }
    hx = moon.y * moon.vz - moon.z * moon.vy;
    hy = moon.z * moon.vx - moon.x * moon.vz;
    result.status = ASTRO_SUCCESS;
    result.angle = normalize_degrees(atan2(hx, -hy) * AL_RAD2DEG);
    return result;
}

static double mean_lunar_node(astro_time_t time)
{
    const double t = time.tt / 36525.0;
    return normalize_degrees(
        125.04455501
        - 1934.1361849 * t
        + 0.0020762 * t * t
        + t * t * t / 467410.0
        - t * t * t * t / 60616000.0);
}


static astro_status_t tribhaga_solar_period(
    astro_time_t time,
    astro_observer_t observer,
    int *is_day,
    int *third,
    double *start_offset_days,
    double *end_offset_days)
{
    const astro_time_t back = Astronomy_AddDays(time, -1.0);
    const astro_search_result_t previous_rise = Astronomy_SearchRiseSet(
        BODY_SUN, observer, DIRECTION_RISE, back, 2.0);
    const astro_search_result_t previous_set = Astronomy_SearchRiseSet(
        BODY_SUN, observer, DIRECTION_SET, back, 2.0);
    const astro_search_result_t next_rise = Astronomy_SearchRiseSet(
        BODY_SUN, observer, DIRECTION_RISE, time, 2.0);
    const astro_search_result_t next_set = Astronomy_SearchRiseSet(
        BODY_SUN, observer, DIRECTION_SET, time, 2.0);
    astro_time_t start;
    astro_time_t end;
    double fraction;
    int part;

    if (previous_rise.status != ASTRO_SUCCESS)
        return previous_rise.status;
    if (previous_set.status != ASTRO_SUCCESS)
        return previous_set.status;
    if (next_rise.status != ASTRO_SUCCESS)
        return next_rise.status;
    if (next_set.status != ASTRO_SUCCESS)
        return next_set.status;

    /* The later of the most recent rise/set events identifies whether the
       observation is in daylight or night. Search from one day earlier so
       the first returned event of each type is the relevant previous event. */
    *is_day = previous_rise.time.ut > previous_set.time.ut ? 1 : 0;
    if (*is_day) {
        start = previous_rise.time;
        end = next_set.time;
    } else {
        start = previous_set.time;
        end = next_rise.time;
    }

    if (!(end.ut > start.ut) ||
        time.ut < start.ut - 1.0e-9 ||
        time.ut > end.ut + 1.0e-9)
        return ASTRO_INCONSISTENT_TIMES;

    fraction = (time.ut - start.ut) / (end.ut - start.ut);
    if (fraction < 0.0)
        fraction = 0.0;
    if (fraction >= 1.0)
        fraction = 1.0 - 1.0e-12;
    part = (int)floor(3.0 * fraction) + 1;
    if (part < 1) part = 1;
    if (part > 3) part = 3;

    *third = part;
    *start_offset_days = start.ut - time.ut;
    *end_offset_days = end.ut - time.ut;
    return ASTRO_SUCCESS;
}


static astro_angle_result_t sidereal_sun_longitude(astro_time_t time)
{
    astro_angle_result_t sun = longitude_at(BODY_SUN, time);
    astro_angle_result_t ayanamsha;
    if (sun.status != ASTRO_SUCCESS)
        return sun;
    ayanamsha = lahiri_ayanamsha(time);
    if (ayanamsha.status != ASTRO_SUCCESS)
        return ayanamsha;
    sun.angle = normalize_degrees(sun.angle - ayanamsha.angle);
    return sun;
}

static astro_search_result_t previous_sidereal_sun_ingress(
    astro_time_t time,
    double target_sidereal_longitude)
{
    const double mean_solar_motion = 0.98564736;
    astro_search_result_t result;
    astro_angle_result_t current = sidereal_sun_longitude(time);
    double delta;
    astro_time_t left;
    astro_time_t right;
    double f_left = NAN;
    double f_right = NAN;
    int expand;
    int iteration;

    result.status = current.status;
    result.time = time;
    if (current.status != ASTRO_SUCCESS)
        return result;

    delta = normalize_degrees(current.angle - target_sidereal_longitude);
    {
        const astro_time_t guess = Astronomy_AddDays(time, -delta / mean_solar_motion);
        left = Astronomy_AddDays(guess, -2.0);
        right = Astronomy_AddDays(guess, 2.0);
    }

    for (expand = 0; expand < 8; ++expand) {
        const astro_angle_result_t left_longitude = sidereal_sun_longitude(left);
        const astro_angle_result_t right_longitude = sidereal_sun_longitude(right);
        if (left_longitude.status != ASTRO_SUCCESS) {
            result.status = left_longitude.status;
            return result;
        }
        if (right_longitude.status != ASTRO_SUCCESS) {
            result.status = right_longitude.status;
            return result;
        }
        f_left = signed_angle_difference(left_longitude.angle, target_sidereal_longitude);
        f_right = signed_angle_difference(right_longitude.angle, target_sidereal_longitude);
        if (f_left <= 0.0 && f_right >= 0.0)
            break;
        left = Astronomy_AddDays(left, -2.0);
        right = Astronomy_AddDays(right, 2.0);
    }

    if (!(f_left <= 0.0 && f_right >= 0.0)) {
        result.status = ASTRO_SEARCH_FAILURE;
        return result;
    }

    for (iteration = 0; iteration < 64; ++iteration) {
        const double middle_ut = 0.5 * (left.ut + right.ut);
        const astro_time_t middle = Astronomy_TimeFromDays(middle_ut);
        const astro_angle_result_t middle_longitude = sidereal_sun_longitude(middle);
        double f_middle;
        if (middle_longitude.status != ASTRO_SUCCESS) {
            result.status = middle_longitude.status;
            return result;
        }
        f_middle = signed_angle_difference(
            middle_longitude.angle, target_sidereal_longitude);
        if (f_middle >= 0.0)
            right = middle;
        else
            left = middle;
        if ((right.ut - left.ut) * 86400.0 < 0.01)
            break;
    }

    result.status = ASTRO_SUCCESS;
    result.time = Astronomy_TimeFromDays(0.5 * (left.ut + right.ut));
    if (result.time.ut > time.ut + 1.0e-9)
        result.status = ASTRO_INCONSISTENT_TIMES;
    return result;
}

static astro_search_result_t previous_sunrise(
    astro_time_t time,
    astro_observer_t observer)
{
    const astro_time_t back = Astronomy_AddDays(time, -1.1);
    astro_search_result_t result = Astronomy_SearchRiseSet(
        BODY_SUN, observer, DIRECTION_RISE, back, 1.1);
    if (result.status == ASTRO_SUCCESS && result.time.ut > time.ut + 1.0e-9)
        result.status = ASTRO_INCONSISTENT_TIMES;
    return result;
}

static astro_status_t solar_ingress_context(
    astro_time_t time,
    astro_observer_t observer,
    double *varsha_ingress_offset_days,
    double *varsha_day_start_offset_days,
    double *masa_ingress_offset_days,
    double *masa_day_start_offset_days)
{
    const astro_angle_result_t current = sidereal_sun_longitude(time);
    astro_search_result_t varsha_ingress;
    astro_search_result_t masa_ingress;
    astro_search_result_t varsha_sunrise;
    astro_search_result_t masa_sunrise;
    double masa_target;

    if (current.status != ASTRO_SUCCESS)
        return current.status;
    masa_target = 30.0 * floor(current.angle / 30.0);
    varsha_ingress = previous_sidereal_sun_ingress(time, 0.0);
    if (varsha_ingress.status != ASTRO_SUCCESS)
        return varsha_ingress.status;
    masa_ingress = previous_sidereal_sun_ingress(time, masa_target);
    if (masa_ingress.status != ASTRO_SUCCESS)
        return masa_ingress.status;
    varsha_sunrise = previous_sunrise(varsha_ingress.time, observer);
    if (varsha_sunrise.status != ASTRO_SUCCESS)
        return varsha_sunrise.status;
    masa_sunrise = previous_sunrise(masa_ingress.time, observer);
    if (masa_sunrise.status != ASTRO_SUCCESS)
        return masa_sunrise.status;

    *varsha_ingress_offset_days = varsha_ingress.time.ut - time.ut;
    *varsha_day_start_offset_days = varsha_sunrise.time.ut - time.ut;
    *masa_ingress_offset_days = masa_ingress.time.ut - time.ut;
    *masa_day_start_offset_days = masa_sunrise.time.ut - time.ut;
    return ASTRO_SUCCESS;
}


static astro_angle_result_t tropical_ascendant(
    astro_time_t time,
    double latitude,
    double longitude);

static double wrap_degrees_180(double angle)
{
    double result = fmod(angle + 180.0, 360.0);
    if (result < 0.0)
        result += 360.0;
    return result - 180.0;
}

/*
 * Independently implemented Newcomb/Kinoshita-1975 precession matrix.
 * The coefficients are frozen by ASTRO LOGIC's governed KP classic profile.
 * direction > 0: epoch J -> J2000; direction < 0: J2000 -> epoch J.
 */
static void kp_newcomb_precess(double vector[3], double J, int direction)
{
    const double mills = 365242.198782;
    const double t1 = (AL_J2000 - AL_B1850) / mills;
    const double t2 = (J - AL_B1850) / mills;
    const double T = t2 - t1;
    const double T2 = T * T;
    const double T3 = T2 * T;
    const double Z1 = 23035.5548 + 139.720 * t1 + 0.069 * t1 * t1;
    const double Z = (
        Z1 * T + (30.242 - 0.269 * t1) * T2 + 17.996 * T3
    ) * AL_DEG2RAD / 3600.0;
    const double z = (
        Z1 * T + (109.478 - 0.387 * t1) * T2 + 18.324 * T3
    ) * AL_DEG2RAD / 3600.0;
    const double TH = (
        (20051.125 - 85.294 * t1 - 0.365 * t1 * t1) * T
        + (-42.647 - 0.365 * t1) * T2
        - 41.802 * T3
    ) * AL_DEG2RAD / 3600.0;
    const double sinth = sin(TH);
    const double costh = cos(TH);
    const double sinZ = sin(Z);
    const double cosZ = cos(Z);
    const double sinz = sin(z);
    const double cosz = cos(z);
    const double A = cosZ * costh;
    const double B = sinZ * costh;
    double out[3];

    if (direction < 0) {
        out[0] = (A*cosz - sinZ*sinz)*vector[0]
            - (B*cosz + cosZ*sinz)*vector[1]
            - sinth*cosz*vector[2];
        out[1] = (A*sinz + sinZ*cosz)*vector[0]
            - (B*sinz - cosZ*cosz)*vector[1]
            - sinth*sinz*vector[2];
        out[2] = cosZ*sinth*vector[0]
            - sinZ*sinth*vector[1]
            + costh*vector[2];
    } else {
        out[0] = (A*cosz - sinZ*sinz)*vector[0]
            + (A*sinz + sinZ*cosz)*vector[1]
            + cosZ*sinth*vector[2];
        out[1] = -(B*cosz + cosZ*sinz)*vector[0]
            - (B*sinz - cosZ*cosz)*vector[1]
            - sinZ*sinth*vector[2];
        out[2] = -sinth*cosz*vector[0]
            - sinth*sinz*vector[1]
            + costh*vector[2];
    }
    vector[0] = out[0];
    vector[1] = out[1];
    vector[2] = out[2];
}

static double kp_newcomb_obliquity(double J)
{
    const double Tn = (J - 2396758.0) / 36525.0;
    const double arcsec =
        0.0017 * Tn * Tn * Tn
        - 0.0085 * Tn * Tn
        - 46.837 * Tn
        + 84451.68;
    return arcsec * AL_DEG2RAD / 3600.0;
}

static astro_angle_result_t kp_classic_ayanamsha(astro_time_t time)
{
    astro_angle_result_t result;
    const double jd_et = AL_J2000 + time.tt;
    double vector[3] = { 1.0, 0.0, 0.0 };
    double eps;
    double y;

    result.status = ASTRO_INVALID_PARAMETER;
    result.angle = NAN;
    if (jd_et < KP_VALID_START_JD || jd_et > KP_VALID_END_JD)
        return result;

    if (fabs(jd_et - AL_J2000) > 1.0e-12)
        kp_newcomb_precess(vector, jd_et, +1);
    kp_newcomb_precess(vector, AL_J1900, -1);

    eps = kp_newcomb_obliquity(AL_J1900);
    y = vector[1] * cos(eps) + vector[2] * sin(eps);
    result.status = ASTRO_SUCCESS;
    result.angle = normalize_degrees(
        -atan2(y, vector[0]) * AL_RAD2DEG + KP_CLASSIC_AYAN_J1900);
    return result;
}

static astro_angle_result_t tropical_mc(astro_time_t time, double longitude)
{
    astro_rotation_t rotation = Astronomy_Rotation_EQD_ECT(&time);
    astro_angle_result_t result;
    double obliquity;
    double armc;
    double theta;

    result.status = rotation.status;
    result.angle = NAN;
    if (rotation.status != ASTRO_SUCCESS)
        return result;

    obliquity = atan2(rotation.rot[2][1], rotation.rot[1][1]);
    armc = normalize_degrees(15.0 * Astronomy_SiderealTime(&time) + longitude);
    theta = armc * AL_DEG2RAD;
    result.status = ASTRO_SUCCESS;
    result.angle = normalize_degrees(
        atan2(sin(theta), cos(theta) * cos(obliquity)) * AL_RAD2DEG);
    return result;
}

static int placidus_residual(
    double ecliptic_longitude,
    double armc,
    double latitude,
    double obliquity,
    int house,
    double *residual)
{
    const double lambda = normalize_degrees(ecliptic_longitude) * AL_DEG2RAD;
    const double eps = obliquity;
    const double x = cos(lambda);
    const double y = sin(lambda) * cos(eps);
    const double z = sin(lambda) * sin(eps);
    const double ra = normalize_degrees(atan2(y, x) * AL_RAD2DEG);
    const double dec = asin(z);
    const double phi = latitude * AL_DEG2RAD;
    const double cos_h0 = -tan(phi) * tan(dec);
    double h0;
    double H;

    if (cos_h0 <= -1.0 || cos_h0 >= 1.0)
        return ASTRO_SEARCH_FAILURE;

    h0 = acos(cos_h0) * AL_RAD2DEG;
    H = wrap_degrees_180(armc - ra);

    switch (house) {
        case 11: *residual = H + h0 / 3.0; break;
        case 12: *residual = H + 2.0 * h0 / 3.0; break;
        case 2: *residual = H + 60.0 + 2.0 * h0 / 3.0; break;
        case 3: *residual = H + 120.0 + h0 / 3.0; break;
        default: return ASTRO_INVALID_PARAMETER;
    }
    return ASTRO_SUCCESS;
}

static int solve_placidus_cusp(
    double interval_start,
    double interval_end,
    double armc,
    double latitude,
    double obliquity,
    int house,
    double *longitude_out)
{
    const int scan_steps = 180;
    double x0 = interval_start;
    double f0;
    int status;
    int i;

    status = placidus_residual(
        x0, armc, latitude, obliquity, house, &f0);
    if (status != ASTRO_SUCCESS)
        return status;

    for (i = 1; i <= scan_steps; ++i) {
        const double x1 =
            interval_start + (interval_end - interval_start) * i / scan_steps;
        double f1;
        status = placidus_residual(
            x1, armc, latitude, obliquity, house, &f1);
        if (status != ASTRO_SUCCESS)
            return status;

        if (fabs(f0) < 1.0e-12) {
            *longitude_out = normalize_degrees(x0);
            return ASTRO_SUCCESS;
        }
        if (f0 * f1 <= 0.0 && fabs(f1 - f0) < 90.0) {
            double left = x0;
            double right = x1;
            double fl = f0;
            int iteration;
            for (iteration = 0; iteration < 80; ++iteration) {
                const double middle = 0.5 * (left + right);
                double fm;
                status = placidus_residual(
                    middle, armc, latitude, obliquity, house, &fm);
                if (status != ASTRO_SUCCESS)
                    return status;
                if (fabs(fm) < 1.0e-12 || fabs(right - left) < 1.0e-11) {
                    *longitude_out = normalize_degrees(middle);
                    return ASTRO_SUCCESS;
                }
                if (fl * fm <= 0.0) {
                    right = middle;
                } else {
                    left = middle;
                    fl = fm;
                }
            }
            *longitude_out = normalize_degrees(0.5 * (left + right));
            return ASTRO_SUCCESS;
        }
        x0 = x1;
        f0 = f1;
    }
    return ASTRO_SEARCH_FAILURE;
}

static int calculate_placidus_cusps(
    astro_time_t time,
    double latitude,
    double longitude,
    double cusps[12],
    double *ascendant_out,
    double *mc_out)
{
    astro_rotation_t rotation = Astronomy_Rotation_EQD_ECT(&time);
    astro_angle_result_t asc;
    astro_angle_result_t mc;
    double obliquity;
    double armc;
    double asc_u;
    double mc_u;
    double ic_u;
    int status;

    if (rotation.status != ASTRO_SUCCESS)
        return rotation.status;
    obliquity = atan2(rotation.rot[2][1], rotation.rot[1][1]);
    if (fabs(latitude) >= 90.0 - fabs(obliquity * AL_RAD2DEG))
        return ASTRO_SEARCH_FAILURE;

    asc = tropical_ascendant(time, latitude, longitude);
    mc = tropical_mc(time, longitude);
    if (asc.status != ASTRO_SUCCESS)
        return asc.status;
    if (mc.status != ASTRO_SUCCESS)
        return mc.status;

    armc = normalize_degrees(15.0 * Astronomy_SiderealTime(&time) + longitude);
    mc_u = mc.angle;
    asc_u = asc.angle;
    while (asc_u <= mc_u)
        asc_u += 360.0;
    while (asc_u - mc_u > 180.0)
        asc_u -= 360.0;
    if (asc_u <= mc_u)
        asc_u += 360.0;
    ic_u = mc_u + 180.0;
    while (ic_u <= asc_u)
        ic_u += 360.0;

    cusps[0] = asc.angle;
    cusps[9] = mc.angle;

    status = solve_placidus_cusp(
        mc_u, asc_u, armc, latitude, obliquity, 11, &cusps[10]);
    if (status != ASTRO_SUCCESS) return status;
    status = solve_placidus_cusp(
        mc_u, asc_u, armc, latitude, obliquity, 12, &cusps[11]);
    if (status != ASTRO_SUCCESS) return status;
    status = solve_placidus_cusp(
        asc_u, ic_u, armc, latitude, obliquity, 2, &cusps[1]);
    if (status != ASTRO_SUCCESS) return status;
    status = solve_placidus_cusp(
        asc_u, ic_u, armc, latitude, obliquity, 3, &cusps[2]);
    if (status != ASTRO_SUCCESS) return status;

    cusps[3] = normalize_degrees(cusps[9] + 180.0);
    cusps[4] = normalize_degrees(cusps[10] + 180.0);
    cusps[5] = normalize_degrees(cusps[11] + 180.0);
    cusps[6] = normalize_degrees(cusps[0] + 180.0);
    cusps[7] = normalize_degrees(cusps[1] + 180.0);
    cusps[8] = normalize_degrees(cusps[2] + 180.0);

    *ascendant_out = asc.angle;
    *mc_out = mc.angle;
    return ASTRO_SUCCESS;
}

static astro_angle_result_t tropical_ascendant(
    astro_time_t time,
    double latitude,
    double longitude)
{
    astro_rotation_t rotation = Astronomy_Rotation_EQD_ECT(&time);
    astro_angle_result_t result;
    double obliquity;
    double local_sidereal;
    double theta;
    double phi;

    result.status = rotation.status;
    result.angle = NAN;
    if (rotation.status != ASTRO_SUCCESS)
        return result;
    obliquity = atan2(rotation.rot[2][1], rotation.rot[1][1]);
    local_sidereal = normalize_degrees(
        15.0 * Astronomy_SiderealTime(&time) + longitude);
    theta = local_sidereal / AL_RAD2DEG;
    phi = latitude / AL_RAD2DEG;
    result.status = ASTRO_SUCCESS;
    result.angle = normalize_degrees(
        atan2(
            -cos(theta),
            sin(theta) * cos(obliquity) + tan(phi) * sin(obliquity))
        * AL_RAD2DEG + 180.0);
    return result;
}

const char *al_astronomy_engine_version(void)
{
    return "astronomy-engine-c-2.1.19";
}

al_position al_geocentric_position(
    int body,
    int year,
    int month,
    int day,
    int hour,
    int minute,
    double second)
{
    const astro_body_t mapped = map_body(body);
    const astro_time_t time = Astronomy_MakeTime(
        year, month, day, hour, minute, second);
    astro_angle_result_t current;
    astro_angle_result_t before;
    astro_angle_result_t after;
    astro_vector_t current_vector;
    astro_ecliptic_t current_ecliptic;
    al_position result = { ASTRO_INVALID_BODY, NAN, NAN, NAN };

    if (mapped == BODY_INVALID)
        return result;

    current = longitude_at(mapped, time);
    result.status = current.status;
    if (current.status != ASTRO_SUCCESS)
        return result;

    current_vector = Astronomy_GeoVector(mapped, time, ABERRATION);
    if (current_vector.status != ASTRO_SUCCESS) {
        result.status = current_vector.status;
        return result;
    }
    current_ecliptic = Astronomy_Ecliptic(current_vector);
    if (current_ecliptic.status != ASTRO_SUCCESS) {
        result.status = current_ecliptic.status;
        return result;
    }

    before = longitude_at(mapped, Astronomy_AddDays(time, -SPEED_SAMPLE_DAYS));
    after = longitude_at(mapped, Astronomy_AddDays(time, SPEED_SAMPLE_DAYS));
    if (before.status != ASTRO_SUCCESS || after.status != ASTRO_SUCCESS) {
        result.status = before.status != ASTRO_SUCCESS
            ? before.status
            : after.status;
        return result;
    }

    result.tropical_longitude = current.angle;
    result.ecliptic_latitude = current_ecliptic.elat;
    result.longitude_speed_per_day = signed_angle_difference(
        after.angle, before.angle) / (2.0 * SPEED_SAMPLE_DAYS);
    return result;
}


al_kp_frame al_calculate_kp_frame(
    int year,
    int month,
    int day,
    int hour,
    int minute,
    double second,
    double latitude,
    double longitude)
{
    astro_time_t time;
    astro_angle_result_t ayanamsha;
    astro_angle_result_t true_node;
    double mean_node;
    double tropical_cusps[12];
    double ascendant = NAN;
    double mc = NAN;
    int placidus_status;
    int i;
    al_kp_frame result;
    result.status = ASTRO_INVALID_PARAMETER;
    result.placidus_status = ASTRO_NOT_INITIALIZED;
    result.krishnamurti_ayanamsha = NAN;
    result.tropical_ascendant = NAN;
    result.tropical_mc = NAN;
    result.sidereal_ascendant = NAN;
    result.sidereal_mc = NAN;
    result.true_node_tropical = NAN;
    result.mean_node_tropical = NAN;
    for (i = 0; i < 12; ++i) {
        result.tropical_cusps[i] = NAN;
        result.sidereal_cusps[i] = NAN;
    }

    if (!isfinite(latitude) || latitude < -90.0 || latitude > 90.0 ||
        !isfinite(longitude) || longitude < -180.0 || longitude > 180.0)
        return result;

    time = Astronomy_MakeTime(year, month, day, hour, minute, second);
    ayanamsha = kp_classic_ayanamsha(time);
    if (ayanamsha.status != ASTRO_SUCCESS) {
        result.status = ayanamsha.status;
        return result;
    }

    placidus_status = calculate_placidus_cusps(
        time, latitude, longitude, tropical_cusps, &ascendant, &mc);
    result.placidus_status = placidus_status;
    if (placidus_status != ASTRO_SUCCESS) {
        result.status = placidus_status;
        return result;
    }

    true_node = true_lunar_node(time);
    if (true_node.status != ASTRO_SUCCESS) {
        result.status = true_node.status;
        return result;
    }
    mean_node = mean_lunar_node(time);

    result.status = ASTRO_SUCCESS;
    result.krishnamurti_ayanamsha = ayanamsha.angle;
    result.tropical_ascendant = ascendant;
    result.tropical_mc = mc;
    result.sidereal_ascendant = normalize_degrees(ascendant - ayanamsha.angle);
    result.sidereal_mc = normalize_degrees(mc - ayanamsha.angle);
    result.true_node_tropical = true_node.angle;
    result.mean_node_tropical = mean_node;
    for (i = 0; i < 12; ++i) {
        result.tropical_cusps[i] = tropical_cusps[i];
        result.sidereal_cusps[i] =
            normalize_degrees(tropical_cusps[i] - ayanamsha.angle);
    }
    return result;
}

al_western_frame al_calculate_western_frame(
    int year,
    int month,
    int day,
    int hour,
    int minute,
    double second,
    double latitude,
    double longitude)
{
    astro_time_t time;
    astro_angle_result_t true_node;
    double mean_node;
    double tropical_cusps[12];
    double ascendant = NAN;
    double mc = NAN;
    int placidus_status;
    int i;
    al_western_frame result;

    result.status = ASTRO_INVALID_PARAMETER;
    result.placidus_status = ASTRO_NOT_INITIALIZED;
    result.tropical_ascendant = NAN;
    result.tropical_mc = NAN;
    result.true_node_tropical = NAN;
    result.mean_node_tropical = NAN;
    for (i = 0; i < 12; ++i)
        result.tropical_cusps[i] = NAN;

    if (!isfinite(latitude) || latitude < -90.0 || latitude > 90.0 ||
        !isfinite(longitude) || longitude < -180.0 || longitude > 180.0)
        return result;

    time = Astronomy_MakeTime(year, month, day, hour, minute, second);
    {
        astro_angle_result_t asc = tropical_ascendant(time, latitude, longitude);
        astro_angle_result_t midheaven = tropical_mc(time, longitude);
        if (asc.status != ASTRO_SUCCESS) {
            result.status = asc.status;
            return result;
        }
        if (midheaven.status != ASTRO_SUCCESS) {
            result.status = midheaven.status;
            return result;
        }
        ascendant = asc.angle;
        mc = midheaven.angle;
    }

    true_node = true_lunar_node(time);
    if (true_node.status != ASTRO_SUCCESS) {
        result.status = true_node.status;
        return result;
    }
    mean_node = mean_lunar_node(time);

    placidus_status = calculate_placidus_cusps(
        time, latitude, longitude, tropical_cusps, &ascendant, &mc);
    result.placidus_status = placidus_status;

    result.status = ASTRO_SUCCESS;
    result.tropical_ascendant = ascendant;
    result.tropical_mc = mc;
    result.true_node_tropical = true_node.angle;
    result.mean_node_tropical = mean_node;
    if (placidus_status == ASTRO_SUCCESS) {
        for (i = 0; i < 12; ++i)
            result.tropical_cusps[i] = tropical_cusps[i];
    }
    return result;
}

al_frame_supplement al_calculate_frame_supplement(
    int year,
    int month,
    int day,
    int hour,
    int minute,
    double second,
    double latitude,
    double longitude)
{
    astro_time_t time;
    astro_angle_result_t ayanamsha;
    astro_angle_result_t ascendant;
    astro_angle_result_t true_node;
    astro_angle_result_t true_node_before;
    astro_angle_result_t true_node_after;
    double mean_node;
    double mean_node_before;
    double mean_node_after;
    astro_observer_t observer;
    astro_func_result_t sun_hour_angle;
    astro_status_t tribhaga_status;
    int tribhaga_is_day = 0;
    int tribhaga_third = 0;
    double tribhaga_period_start_offset_days = NAN;
    double tribhaga_period_end_offset_days = NAN;
    astro_search_result_t astrological_day_start;
    astro_status_t solar_ingress_status;
    double varsha_ingress_offset_days = NAN;
    double varsha_day_start_offset_days = NAN;
    double masa_ingress_offset_days = NAN;
    double masa_day_start_offset_days = NAN;
    al_frame_supplement result = {
        ASTRO_INVALID_PARAMETER, NAN, NAN, NAN, NAN, NAN, NAN, NAN,
        ASTRO_NOT_INITIALIZED, 0, 0, NAN, NAN,
        ASTRO_NOT_INITIALIZED, NAN,
        ASTRO_NOT_INITIALIZED, NAN, NAN, NAN, NAN
    };

    if (!isfinite(latitude) || latitude < -90.0 || latitude > 90.0 ||
        !isfinite(longitude) || longitude < -180.0 || longitude > 180.0)
        return result;
    time = Astronomy_MakeTime(year, month, day, hour, minute, second);
    observer = Astronomy_MakeObserver(latitude, longitude, 0.0);
    sun_hour_angle = Astronomy_HourAngle(BODY_SUN, &time, observer);
    tribhaga_status = tribhaga_solar_period(
        time, observer, &tribhaga_is_day, &tribhaga_third,
        &tribhaga_period_start_offset_days, &tribhaga_period_end_offset_days);
    astrological_day_start = previous_sunrise(time, observer);
    solar_ingress_status = solar_ingress_context(
        time, observer,
        &varsha_ingress_offset_days, &varsha_day_start_offset_days,
        &masa_ingress_offset_days, &masa_day_start_offset_days);
    ayanamsha = lahiri_ayanamsha(time);
    ascendant = tropical_ascendant(time, latitude, longitude);
    true_node = true_lunar_node(time);
    true_node_before = true_lunar_node(
        Astronomy_AddDays(time, -SPEED_SAMPLE_DAYS));
    true_node_after = true_lunar_node(
        Astronomy_AddDays(time, SPEED_SAMPLE_DAYS));
    mean_node = mean_lunar_node(time);
    mean_node_before = mean_lunar_node(
        Astronomy_AddDays(time, -SPEED_SAMPLE_DAYS));
    mean_node_after = mean_lunar_node(
        Astronomy_AddDays(time, SPEED_SAMPLE_DAYS));
    if (sun_hour_angle.status != ASTRO_SUCCESS) {
        result.status = sun_hour_angle.status;
        return result;
    }
    if (ayanamsha.status != ASTRO_SUCCESS) {
        result.status = ayanamsha.status;
        return result;
    }
    if (ascendant.status != ASTRO_SUCCESS) {
        result.status = ascendant.status;
        return result;
    }
    if (true_node.status != ASTRO_SUCCESS) {
        result.status = true_node.status;
        return result;
    }
    if (true_node_before.status != ASTRO_SUCCESS ||
        true_node_after.status != ASTRO_SUCCESS) {
        result.status = true_node_before.status != ASTRO_SUCCESS
            ? true_node_before.status
            : true_node_after.status;
        return result;
    }
    result.status = ASTRO_SUCCESS;
    result.lahiri_ayanamsha = ayanamsha.angle;
    result.tropical_ascendant = ascendant.angle;
    result.true_node_longitude = true_node.angle;
    result.true_node_speed_per_day = signed_angle_difference(
        true_node_after.angle, true_node_before.angle)
        / (2.0 * SPEED_SAMPLE_DAYS);
    result.mean_node_longitude = mean_node;
    result.mean_node_speed_per_day = signed_angle_difference(
        mean_node_after, mean_node_before) / (2.0 * SPEED_SAMPLE_DAYS);
    result.sun_hour_angle_hours = sun_hour_angle.value;
    result.tribhaga_status = tribhaga_status;
    result.tribhaga_is_day = tribhaga_status == ASTRO_SUCCESS ? tribhaga_is_day : 0;
    result.tribhaga_third = tribhaga_status == ASTRO_SUCCESS ? tribhaga_third : 0;
    result.tribhaga_period_start_offset_days =
        tribhaga_status == ASTRO_SUCCESS ? tribhaga_period_start_offset_days : NAN;
    result.tribhaga_period_end_offset_days =
        tribhaga_status == ASTRO_SUCCESS ? tribhaga_period_end_offset_days : NAN;
    result.astrological_day_status = astrological_day_start.status;
    result.astrological_day_start_offset_days =
        astrological_day_start.status == ASTRO_SUCCESS
            ? astrological_day_start.time.ut - time.ut
            : NAN;
    result.solar_ingress_status = solar_ingress_status;
    result.varsha_ingress_offset_days =
        solar_ingress_status == ASTRO_SUCCESS ? varsha_ingress_offset_days : NAN;
    result.varsha_day_start_offset_days =
        solar_ingress_status == ASTRO_SUCCESS ? varsha_day_start_offset_days : NAN;
    result.masa_ingress_offset_days =
        solar_ingress_status == ASTRO_SUCCESS ? masa_ingress_offset_days : NAN;
    result.masa_day_start_offset_days =
        solar_ingress_status == ASTRO_SUCCESS ? masa_day_start_offset_days : NAN;
    return result;
}
