#include <math.h>
#include <stdio.h>

#include "../astro_logic_astronomy.h"

typedef struct reference_fixture {
    int body;
    const char *name;
    double jpl_longitude;
} reference_fixture;

static double angular_error(double actual, double expected)
{
    return fabs(fmod(actual - expected + 540.0, 360.0) - 180.0);
}

int main(void)
{
    static const reference_fixture fixtures[] = {
        { AL_BODY_SUN, "Sun", 352.3837496 },
        { AL_BODY_MOON, "Moon", 107.7249757 },
        { AL_BODY_MARS, "Mars", 235.2504762 },
        { AL_BODY_MERCURY, "Mercury", 356.2301156 },
        { AL_BODY_JUPITER, "Jupiter", 279.5629920 },
        { AL_BODY_VENUS, "Venus", 327.8470168 },
        { AL_BODY_SATURN, "Saturn", 226.1325234 }
    };
    const double tolerance_degrees = 0.01;
    unsigned int index;

    for (index = 0; index < sizeof(fixtures) / sizeof(fixtures[0]); ++index) {
        const reference_fixture fixture = fixtures[index];
        const al_position result = al_geocentric_position(
            fixture.body, 1984, 3, 12, 18, 42, 0.0);
        const double error = angular_error(
            result.tropical_longitude, fixture.jpl_longitude);

        if (result.status != 0 || !isfinite(result.ecliptic_latitude) ||
            result.ecliptic_latitude < -90.0 || result.ecliptic_latitude > 90.0 ||
            !isfinite(result.longitude_speed_per_day)) {
            fprintf(stderr, "%s calculation failed: %d\n",
                fixture.name, result.status);
            return 1;
        }
        printf("%-8s actual=%11.7f lat=%10.7f jpl=%11.7f error=%10.7f\n",
            fixture.name,
            result.tropical_longitude,
            result.ecliptic_latitude,
            fixture.jpl_longitude,
            error);
        if (error > tolerance_degrees) {
            fprintf(stderr, "%s exceeded tolerance %.6f degrees\n",
                fixture.name, tolerance_degrees);
            return 2;
        }
    }

    {
        static const reference_fixture modern_fixtures[] = {
            { AL_BODY_URANUS, "Uranus", 65.3422222222 },
            { AL_BODY_NEPTUNE, "Neptune", 4.0791666667 },
            { AL_BODY_PLUTO, "Pluto", 303.9066666667 }
        };
        const double public_ephemeris_tolerance_degrees = 0.02;
        for (index = 0;
             index < sizeof(modern_fixtures) / sizeof(modern_fixtures[0]);
             ++index) {
            const reference_fixture fixture = modern_fixtures[index];
            const al_position result = al_geocentric_position(
                fixture.body, 2026, 8, 12, 17, 19, 0.0);
            const double error = angular_error(
                result.tropical_longitude, fixture.jpl_longitude);
            if (result.status != 0 || !isfinite(result.tropical_longitude) ||
                !isfinite(result.ecliptic_latitude) ||
                !isfinite(result.longitude_speed_per_day)) {
                fprintf(stderr, "%s modern calculation failed: %d\n",
                    fixture.name, result.status);
                return 14;
            }
            printf("%-8s modern=%11.7f external=%11.7f error=%10.7f\n",
                fixture.name, result.tropical_longitude,
                fixture.jpl_longitude, error);
            if (error > public_ephemeris_tolerance_degrees) {
                fprintf(stderr,
                    "%s exceeded public ephemeris tolerance %.6f degrees\n",
                    fixture.name, public_ephemeris_tolerance_degrees);
                return 15;
            }
        }
    }

    {
        const al_frame_supplement supplement = al_calculate_frame_supplement(
            1984, 3, 12, 18, 42, 0.0, 23.22, 88.37);
        if (supplement.status != 0 ||
            !isfinite(supplement.lahiri_ayanamsha) ||
            !isfinite(supplement.tropical_ascendant) ||
            !isfinite(supplement.true_node_longitude) ||
            !isfinite(supplement.true_node_speed_per_day) ||
            !isfinite(supplement.mean_node_longitude) ||
            !isfinite(supplement.sun_hour_angle_hours) ||
            supplement.tribhaga_status != 0 ||
            !isfinite(supplement.tribhaga_period_start_offset_days) ||
            !isfinite(supplement.tribhaga_period_end_offset_days) ||
            supplement.astrological_day_status != 0 ||
            !isfinite(supplement.astrological_day_start_offset_days) ||
            supplement.solar_ingress_status != 0 ||
            !isfinite(supplement.varsha_ingress_offset_days) ||
            !isfinite(supplement.varsha_day_start_offset_days) ||
            !isfinite(supplement.masa_ingress_offset_days) ||
            !isfinite(supplement.masa_day_start_offset_days)) {
            fprintf(stderr, "Frame supplement failed: %d\n", supplement.status);
            return 3;
        }
        printf("Lahiri=%11.7f Asc=%11.7f TrueNode=%11.7f (%9.6f/day) MeanNode=%11.7f (%9.6f/day) SunHA=%8.5fh Tribhaga=%s/%d [%0.9f,%0.9f]d AstroDay=%0.9f Varsha=%0.9f/%0.9f Masa=%0.9f/%0.9f\n",
            supplement.lahiri_ayanamsha,
            supplement.tropical_ascendant,
            supplement.true_node_longitude,
            supplement.true_node_speed_per_day,
            supplement.mean_node_longitude,
            supplement.mean_node_speed_per_day,
            supplement.sun_hour_angle_hours,
            supplement.tribhaga_is_day ? "day" : "night",
            supplement.tribhaga_third,
            supplement.tribhaga_period_start_offset_days,
            supplement.tribhaga_period_end_offset_days,
            supplement.astrological_day_start_offset_days,
            supplement.varsha_ingress_offset_days,
            supplement.varsha_day_start_offset_days,
            supplement.masa_ingress_offset_days,
            supplement.masa_day_start_offset_days);
        if (supplement.tropical_ascendant < 180.0 ||
            supplement.tropical_ascendant >= 360.0 ||
            supplement.true_node_speed_per_day >= 0.0 ||
            supplement.mean_node_speed_per_day >= 0.0 ||
            supplement.sun_hour_angle_hours < 0.0 ||
            supplement.sun_hour_angle_hours >= 24.0 ||
            supplement.tribhaga_is_day != 0 ||
            supplement.tribhaga_third != 2 ||
            supplement.tribhaga_period_start_offset_days >= 0.0 ||
            supplement.tribhaga_period_end_offset_days <= 0.0) {
            fprintf(stderr, "Frame supplement regression failed\n");
            return 4;
        }
        if (fabs(supplement.lahiri_ayanamsha - 23.6212396) > 0.000001 ||
            fabs(supplement.tropical_ascendant - 259.8330326) > 0.000001 ||
            fabs(supplement.true_node_longitude - 70.1004066) > 0.000001 ||
            fabs(supplement.mean_node_longitude - 70.7318634) > 0.000001 ||
            fabs(supplement.sun_hour_angle_hours - 12.430224160748) > 0.000001 ||
            fabs(supplement.tribhaga_period_start_offset_days - (-0.269088285379)) > 0.000001 ||
            fabs(supplement.tribhaga_period_end_offset_days - 0.233005742031) > 0.000001 ||
            fabs(supplement.astrological_day_start_offset_days - (-0.766337897683)) > 0.000001 ||
            fabs(supplement.varsha_ingress_offset_days - (-333.653167663402)) > 0.000001 ||
            fabs(supplement.varsha_day_start_offset_days - (-333.787781726798)) > 0.000001 ||
            fabs(supplement.masa_ingress_offset_days - (-28.631338442957)) > 0.000001 ||
            fabs(supplement.masa_day_start_offset_days - (-28.750657258644)) > 0.000001) {
            fprintf(stderr, "Frame supplement golden fixture changed\n");
            return 5;
        }
    }

    {
        const al_frame_supplement polar = al_calculate_frame_supplement(
            2026, 6, 21, 12, 0, 0.0, 89.0, 0.0);
        if (polar.status != 0 || polar.tribhaga_status == 0 ||
            polar.astrological_day_status == 0 || polar.solar_ingress_status == 0) {
            fprintf(stderr, "Polar temporal gating regression failed: frame=%d trib=%d day=%d ingress=%d\n",
                polar.status, polar.tribhaga_status,
                polar.astrological_day_status, polar.solar_ingress_status);
            return 6;
        }
    }


    {
        static const double placidus_reference[12] = {
            259.8330156158061,
            291.1655570892044,
            325.2763143732573,
            359.4110085198155,
            29.8853508434646,
            56.0324815010135,
            79.8330156158061,
            111.1655570892044,
            145.2763143732573,
            179.4110085198155,
            209.8853508434646,
            236.0324815010135
        };
        const al_kp_frame kp = al_calculate_kp_frame(
            1984, 3, 12, 18, 42, 0.0, 23.22, 88.37);
        unsigned int cusp;
        if (kp.status != 0 || kp.placidus_status != 0) {
            fprintf(stderr, "KP native frame failed: frame=%d placidus=%d\n",
                kp.status, kp.placidus_status);
            return 7;
        }
        if (fabs(kp.krishnamurti_ayanamsha - 23.53950781182664) > 0.000001) {
            fprintf(stderr, "KP classic ayanamsha external fixture changed: %.12f\n",
                kp.krishnamurti_ayanamsha);
            return 8;
        }
        for (cusp = 0; cusp < 12; ++cusp) {
            if (angular_error(kp.tropical_cusps[cusp], placidus_reference[cusp])
                    > 0.0001) {
                fprintf(stderr,
                    "KP Placidus cusp %u exceeded external fixture tolerance: "
                    "actual=%.12f reference=%.12f\n",
                    cusp + 1,
                    kp.tropical_cusps[cusp],
                    placidus_reference[cusp]);
                return 9;
            }
            if (angular_error(
                    kp.sidereal_cusps[cusp],
                    kp.tropical_cusps[cusp] - kp.krishnamurti_ayanamsha)
                    > 0.000000001) {
                fprintf(stderr, "KP sidereal cusp projection changed\n");
                return 10;
            }
        }
        printf("KP classic ayanamsha=%11.7f Asc=%11.7f MC=%11.7f "
               "Placidus fixture=PASS\n",
            kp.krishnamurti_ayanamsha,
            kp.tropical_ascendant,
            kp.tropical_mc);
    }

    {
        const al_kp_frame polar = al_calculate_kp_frame(
            2026, 6, 21, 12, 0, 0.0, 89.0, 0.0);
        if (polar.status == 0 || polar.placidus_status == 0) {
            fprintf(stderr,
                "KP Placidus polar gate failed: frame=%d placidus=%d\n",
                polar.status, polar.placidus_status);
            return 11;
        }
    }

    {
        const al_western_frame western = al_calculate_western_frame(
            1984, 3, 12, 18, 42, 0.0, 23.22, 88.37);
        if (western.status != 0 || western.placidus_status != 0 ||
            angular_error(western.tropical_ascendant, 259.8330156158061) > 0.0001 ||
            angular_error(western.tropical_mc, 179.4110085198155) > 0.0001 ||
            !isfinite(western.true_node_tropical) ||
            !isfinite(western.mean_node_tropical)) {
            fprintf(stderr,
                "Western native frame regression failed: frame=%d placidus=%d asc=%.12f mc=%.12f\n",
                western.status, western.placidus_status,
                western.tropical_ascendant, western.tropical_mc);
            return 12;
        }
    }

    {
        const al_western_frame polar = al_calculate_western_frame(
            2026, 6, 21, 12, 0, 0.0, 89.0, 0.0);
        if (polar.status != 0 || polar.placidus_status == 0 ||
            !isfinite(polar.tropical_ascendant) ||
            !isfinite(polar.tropical_mc)) {
            fprintf(stderr,
                "Western polar core/fallback gate failed: frame=%d placidus=%d asc=%.12f mc=%.12f\n",
                polar.status, polar.placidus_status,
                polar.tropical_ascendant, polar.tropical_mc);
            return 13;
        }
    }

    return 0;
}
