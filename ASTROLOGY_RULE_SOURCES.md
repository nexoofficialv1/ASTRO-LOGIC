# Astrology rule sources

This file records the public references used to define deterministic rule
profiles. A reference documents a rule; it does not remove the requirement for
professional astrologer review or make an interpretation scientifically proven.

## Western v082 provenance routing

Western tropical astronomy, Traditional/Modern rulership profiles, optional minor-aspect angles, pattern geometry and operational-orb governance are maintained separately in `WESTERN_RULE_SOURCES.md`. v082 does not use Western evidence to raise Vedic/KP/Numerology confidence and does not inject modern rulers into the traditional essential-dignity table.

## Vimshottari multi-level interpretation profile v2

- Saravali Vimshottari overview:
  https://saravali.github.io/astrology/dasa_vimsottari.html
- AstroCentral Antardasha/Pratyantardasha hierarchy and timing overview:
  https://astrocentral.com/articles/antardasha-pratyantar-dasha

The applied profile keeps Mahadasha as the broadest theme, Antardasha as its
modifier and Pratyantardasha as the narrowest timing/activation layer. Judgment
uses natal house placement, ascendant-specific lordship and D1/D9 dignity; node
periods are qualified through their sign dispositor. Version
`pratyantardasha-interpretation-v1` applies those chart-specific profiles to all
729 MD/AD/PD periods and classifies the PD lord as reinforcing, counter-trend or
neutral relative to the weighted MD/AD direction. Repeated life areas across at
least two levels receive priority. The UI's explicit 3:2:1 weighting is an ASTRO
LOGIC versioned synthesis policy—not a quotation from either reference. The
engine does not hard-code fixed 729 event outcomes. Transits, chart promise and
the consultation question are still required before an astrologer confirms an
event.

## Parashari full sign aspects

- Brihat Parashara Hora Shastra, Chapter 26 translation:
  https://jyotishvidya.com/ch26.htm
- Applied profile: every classical planet has the full seventh aspect; Mars
  additionally has full fourth/eighth aspects, Jupiter fifth/ninth, and Saturn
  third/tenth.
- Rahu/Ketu aspects are excluded because traditions differ.

## Shadbala Drik Bala / Sphuta-Drishti profile v1

- Brihat Parashara Hora Shastra, Chapter 26 aspect evaluation translation:
  https://jyotishvidya.com/ch26.htm
- Sphuta-Drishti piecewise reference and special-planet curves:
  https://saravali.github.io/astrology/drishti_sputa.html
- Graha Sutras discussion of the corrupt/variant Jupiter 240°–270° branch and a
  continuity-preserving correction:
  https://pdfcoffee.com/graha-drishtipdf-pdf-free.html
- BPHS 27.19 local-translation summary for Drik weighting:
  https://astrocentral.com/articles/shadbala-intro
- Natural benefic/malefic classification and Mercury association rule:
  https://astrocentral.com/articles/benefics-malefics-in-houses

The applied `bphsSphutaDrishtiDrikV1` profile calculates exact forward
longitude difference from aspector to target and returns 0..60 raw Sphuta
Drishti virupas. The common six-range Chapter-26 curve is retained; Mars,
Jupiter and Saturn use their special full-aspect curves. The Jupiter 240°–270°
branch is explicitly versioned as the continuity-preserving corrected envelope
(60 at 240°, 15 at 270°) because published literal readings conflict. This
choice is never hidden as a universal text reading.

For each target planet, Drik Bala adds one quarter of a benefic received aspect
and subtracts one quarter of a malefic received aspect, then super-adds the full
measured aspect of Mercury and Jupiter under the selected BPHS 27.19 local
translation profile. Sun/Mars/Saturn are malefic; Venus/Jupiter benefic; Moon is
benefic while waxing and malefic while waning. Mercury's quarter-term nature is
benefic unless it is joined in the same sidereal sign by a classical malefic
(Sun/Mars/Saturn or a waning Moon). Rahu/Ketu are excluded from Shadbala Drik.
The stored Drik result may be negative.

## Combustion profile v1

- Brihat Parashara Hora Shastra Chapter 7 translation/commentary, combustion
  table attributed there to Surya Siddhanta:
  https://jyotishvidya.com/ch7.htm
- Archive text of the R. Santhanam English edition:
  https://archive.org/stream/BPHSEnglish/BPHS%20-%201%20RSanthanam_djvu.txt

| Planet | Direct | Retrograde |
| --- | ---: | ---: |
| Moon | 12° | Not applicable |
| Mars | 17° | 8° |
| Mercury | 14° | 12° |
| Jupiter | 11° | 11° |
| Venus | 10° | 8° |
| Saturn | 16° | 16° |

The engine uses minimum circular angular separation from the Sun. Rahu and Ketu
are not marked combust. A combustion match creates a review flag, not a claim
that the planet is destroyed or incapable of results.

## Natural relationships and Moolatrikona profile v1

- Brihat Parashara Hora Shastra English archive, natural relationships section
  and planetary sign-degree descriptions:
  https://archive.org/stream/BPHSEnglish/BPHS%20-%201%20RSanthanam_djvu.txt
- Alternate scan/transcription of the R. Santhanam edition:
  https://archive.org/stream/brihatparasarahorashastrabyr.santhanam/Brihat%20Par%C4%81%C5%9Bara%20Hor%C4%81%20%C5%9Ah%C4%81stra%20By%20R.%20Santhanam_djvu.txt

The applied permanent relationship table is:

| Planet | Friends | Enemies | Neutral |
| --- | --- | --- | --- |
| Sun | Moon, Mars, Jupiter | Venus, Saturn | Mercury |
| Moon | Sun, Mercury | None | Mars, Jupiter, Venus, Saturn |
| Mars | Sun, Moon, Jupiter | Mercury | Venus, Saturn |
| Mercury | Sun, Venus | Moon | Mars, Jupiter, Saturn |
| Jupiter | Sun, Moon, Mars | Mercury, Venus | Saturn |
| Venus | Mercury, Saturn | Sun, Moon | Mars, Jupiter |
| Saturn | Mercury, Venus | Sun, Moon, Mars | Jupiter |

The engine evaluates the placed planet's relationship toward its sign dispositor.
Own-sign placement is labelled `own`.

BPHS verses 56–58 in the same archive define temporary and compound relations.
The 2nd, 3rd, 4th, 10th, 11th and 12th positions are temporary friends; all
others are temporary enemies. The applied compound table is:

| Natural | Temporary | Compound |
| --- | --- | --- |
| Friend | Friend | Great friend |
| Neutral | Friend | Friend |
| Enemy | Friend | Neutral |
| Friend | Enemy | Neutral |
| Neutral | Enemy | Enemy |
| Enemy | Enemy | Great enemy |

Moolatrikona uses deterministic half-open intervals `[start, end)`: Sun in Leo
0°–20°, Moon in Taurus 3°–30°, Mars in Aries 0°–12°, Mercury in Virgo 15°–20°,
Jupiter in Sagittarius 0°–10°, Venus in Libra 0°–15°, and Saturn in Aquarius
0°–20°. The finding supplements rather than replaces broad sign dignity.

## Planetary-war review profile v1

The review is restricted to Mars, Mercury, Jupiter, Venus and Saturn and uses a
1° circular-longitude proximity threshold. The BPHS archive describes northern
placement in planetary war, while Surya Siddhanta traditions also discuss
apparent brightness and disc conditions. Because the current verified output
does not contain celestial latitude/declination, apparent brightness or disc
measurements, the engine records only a review flag and never names a victor.

## Panch Mahapurusha formation profile v1

- Brihat Parashara Hora Shastra English archive; the Yoga chapter and its notes
  distinguish a Pancha Maha Purusha/Hamsa formation from a generic angular
  Moon-Jupiter relationship:
  https://archive.org/stream/BPHSEnglish/BPHS%20-%201%20RSanthanam_djvu.txt
- Formation cross-check describing the shared own/exalted plus Kendra rule and
  the five planet/name mappings:
  https://ournakshatra.com/articles/pancha-mahapurusha-yogas-explained

The applied v1 profile counts Kendras from Lagna only. It requires both
whole-sign house 1/4/7/10 and own-sign/exaltation dignity. Moon-reference
variants are not silently merged into this profile. Combustion, retrograde,
planetary-war proximity and node conjunction are review modifiers, not invented
automatic cancellation rules.

## Kuja-dosha Lagna screen profile v1

Public practitioner references disagree on whether the 2nd house is part of the
core list and on which cancellation rules are authoritative. The documented
comparison used for this conservative split is:

- core 1/4/7/8/12 and extended definitions:
  https://www.shreekundli.com/vedic-astrology/compatibility/manglik-dosha
- broader 1/2/4/7/8/12 practice and the need to evaluate cancellations:
  https://vedika.io/blog/mangal-dosha-api-guide

ASTRO LOGIC therefore labels 1/4/7/8/12 as the core Lagna screen and house 2
as an extended variant. Own/exalted Mars and enabled Jupiter support are shown
only as possible mitigation. The engine does not declare the dosha cancelled,
does not claim scientific validation, and prohibits standalone predictions of
divorce, spouse harm or death.

## BPHS Gajakesari profile v1

- Brihat Parashara Hora Shastra, Chapter 36, verses 3–4 and accompanying
  edition-comparison notes:
  https://archive.org/stream/BPHSEnglish/BPHS%20-%201%20RSanthanam_djvu.txt

The verse requires Jupiter in an angle from Lagna or Moon, support through
conjunction/aspect from another benefic, and avoidance of debilitation,
combustion and inimical sign. The surrounding notes explicitly distinguish
this from simpler Jupiter-Moon angular variants. The enabled benefic-support
profile uses Mercury and Venus; lunar benefic support is deferred until the
judgment contract explicitly supplies and governs waxing/waning status.

## Raja and Dhana formation profile v1

- Brihat Parashara Hora Shastra, Chapter 40 verse 15 and Chapter 41 verses
  2–8 with the general formula stated in the accompanying notes:
  https://archive.org/stream/BPHSEnglish/BPHS%20-%201%20RSanthanam_djvu.txt

The Raja rule applies the Lagna-lord/fifth-lord conjunction in a Kendra or
Trikona. The Dhana rule applies the summarized fifth lord in the fifth and
eleventh lord in the eleventh formula. The engine records formation and the
currently available debilitation/combustion modifiers only; it does not copy
literal promised outcomes or infer activation without Dasha and divisional
strength.

## Navamsha D9 calculation and agreement profile v1

- Brihat Parashara Hora Shastra, Chapter 6, Navamsha verse and notes:
  https://archive.org/stream/BPHSEnglish/BPHS%20-%201%20RSanthanam_djvu.txt

Each sign is divided into nine parts of 3°20′. Distribution begins from the
same sign for movable signs, the ninth for fixed signs and the fifth for dual
signs. ASTRO LOGIC derives the equivalent continuous zodiac index, validates a
supplied D9 sign against sidereal longitude, and records Vargottama when D1 and
D9 signs match. D1-D9 dignity comparison is an auditable application profile,
not a claim of guaranteed results.


## Navamsha D9 house/lord/aspect interpretation profile v1

- Brihat Parashara Hora Shastra, Chapter 6, Navamsha calculation context:
  https://archive.org/stream/BPHSEnglish/BPHS%20-%201%20RSanthanam_djvu.txt
- Brihat Parashara Hora Shastra, Chapter 26, classical full-aspect geometry:
  https://jyotishvidya.com/ch26.htm

ASTRO LOGIC treats the explicit D9 chart as a separate whole-sign structural
frame. Each D9 house receives its sign and classical lord, the lord's D9 house
and broad sign dignity, visible occupants and the already-governed classical
full-sign aspect geometry. D9-ascendant functional ownership is used as an
auditable application profile for classical occupant/aspector direction; it is
not presented as a quotation from the source. The house lord is not scored a
second time merely because it occupies the house. Rahu/Ketu occupancy is
visible but node dignity and node aspects are not invented. Positive and
negative component directions force Mixed, and v1 is capped at Medium
confidence. The family is structural support only and never substitutes for
the natal D1 promise or guarantees an event.

## Vimshottari calendar v2 and activation profile v1

- Brihat Parashara Hora Shastra English archive, Nakshatra Dasha chapters in
  Volume II and the classical 120-year Vimshottari framework:
  https://archive.org/details/BPHSEnglish
- Public implementation-oriented table cross-check for the Moon-Nakshatra
  lords and fixed periods:
  https://saravali.github.io/astrology/dasa_vimsottari.html
- Recursive Pratyantardasha proportional-formula cross-check:
  https://astrocentral.com/articles/antardasha-pratyantar-dasha

The fixed sequence is Ketu 7, Venus 20, Sun 6, Moon 10, Mars 7, Rahu 18,
Jupiter 16, Saturn 19 and Mercury 17 years. The Moon's elapsed fraction within
its 13°20′ birth Nakshatra is applied to the first lord's full period to obtain
the elapsed and remaining Mahadasha balance. Each Antardasha uses the
proportion `Mahadasha years × Antardasha-lord years / 120` and begins with the
Mahadasha lord before continuing through the fixed cycle. Calendar v2 applies
the same proportion recursively inside each Antardasha, beginning with the
Antardasha lord, to produce nine Pratyantardashas and 729 total third-level
periods.

Calendar dates use a documented, versioned sidereal-solar year of 365.25636
days. This choice is emitted with every output so future optional year modes
cannot silently change an old calculation.

The activation profile combines whole-sign placement, D1/D9 dignity and
ascendant-specific functional ownership. Rahu/Ketu use their placement and
their sign dispositor's functional/D1/D9 condition; no independent node
dignity is invented. Opposing Mahadasha and Antardasha scores remain Mixed.
The profile generates medium-confidence review windows, not promised events.
The Pratyantardasha dashboard applies the Pratyantardasha lord's own activation
profile and governed 3:2:1 MD/AD/PD weighting. Selected-date transit confirmation is handled by the separate timing-synthesis
layer; question-specific timing is handled separately so the Vimshottari
calendar itself never becomes an event guarantee.

## Classical Moon-gochara direction profile v2

- Varahamihira, Brihat Samhita, Chapter 104, “On the transits of planets
  (graha-gocara),” English translation hosted by Wisdom Library:
  https://www.wisdomlib.org/hinduism/book/brihat-samhita/d/doc229368.html

The source gives Moon-relative transit effects for Sun, Moon, Mars, Mercury,
Jupiter, Venus and Saturn and states that all planets are benefic in the 11th
from the natal Moon. It also explicitly notes that even a benefic transit acts
according to the nature of the Dasha and the person's circumstances. ASTRO
LOGIC therefore maps only clearly directional houses to Supportive or
Challenging review signals, preserves mixed/limited passages as Mixed, keeps
Sade Sati non-automatic, and does not turn the source's literal descriptions
into guaranteed modern events. Rahu/Ketu are not assigned directional polarity
from this source.

## Dasha × transit comparison methodology v1

- AstroCentral, “Combining Dasha and Transit — A Source-Bounded Comparison
  Method” (2026):
  https://astrocentral.com/articles/dasha-transit-combination
- AstroCentral, “Transit Analysis (Gochara) — Calculation, Tables, and Limits”
  (2026):
  https://astrocentral.com/articles/transit-analysis-gochara

These are used as methodology cross-checks, not as authority for a new
classical event rule. The source review explicitly cautions against misattributing
a universal Dasha-plus-transit rule to an unrelated BPHS chapter. ASTRO LOGIC
therefore keeps Dasha and transit as independently auditable layers and treats
convergence only as confirmation strength. Mixed or absent transit direction is
not silently converted into an adverse result.

## Question-specific target-house timing profile v1

- Varahamihira, Brihat Jataka 1.15, house-domain sequence:
  https://www.wisdomlib.org/hinduism/book/brihat-jataka-by-varahamihira-sanskrit-english/d/doc1501578.html
- Varahamihira, Brihat Jataka 1.18, fourth house as `Veshma` (home) and tenth as
  `Karma`:
  https://www.wisdomlib.org/hinduism/book/brihat-jataka-by-varahamihira-sanskrit-english/d/doc1501581.html

Brihat Jataka 1.15 explicitly associates the second house with family, fifth
with children, seventh with spouse/partnership, tenth with business/action,
eleventh with income and twelfth with expenditure. The existing ASTRO LOGIC
house-synthesis profile also keeps the fifth as intelligence/education, fourth
as home/property, ninth as higher learning/fortune, sixth as service/obstacles
and twelfth as foreign-stay/expense review.

The v1 question engine does not claim that any one target house guarantees an
event. The house sets are an ASTRO LOGIC versioned consultation-routing policy
that must converge with the chart-specific active Dasha profile and an enabled
directional transit occupying a target house from Lagna. The travel/relocation
profile is deliberately restricted to the 12th/4th foreign-stay/home axis; it
does not yet claim a general 3rd/9th journey rule. High confidence, exact dates, divisional timing and node polarity remain outside this profile. Question-specific Timing v2 adds the separately governed Ashtakavarga transit-confirmation profile documented below.

## Conflict and confidence governance profile v1

No new classical astrological event rule is introduced by this layer. It
reuses only already-governed outputs documented above: D1 target-house
synthesis, D1-D9 dignity agreement of target-house lords, topic-weighted
Vimshottari activation and enabled topical transit. The D1 and D1-D9 layers are
explicitly treated as correlated structural evidence rather than two
independent confirmations. Any explicit directional contradiction is preserved
as Mixed, majority voting is disabled, and High confidence is unavailable in
v1. This is an ASTRO LOGIC evidence-governance policy, not an attribution to a
classical source.


## Shadbala foundation source profile v10

- Brihat Parashara Hora Shastra, Chapter 27, Saptavargaja/Ojhayugma verses and
  two-source translation hosted by VedicPupil:
  https://vedicpupil.in/library/brihat-parashara-hora-shastra-book-by-parashara/spashtabal-ch27/2
- BPHS Chapter 27 verse 7 two-source translation for Dig Bala, including the
  zero-strength directions, 180-degree fold and divide-by-3 rule:
  https://vedicpupil.in/library/brihat-parashara-hora-shastra-book-by-parashara/spashtabal-ch27/7
- BPHS Chapter 27 verse 9 for Nathonnata Bala: apparent birth time relative to
  midnight, Nata/Unnata conversion, night-planet/day-planet complement and
  Mercury's constant 60 virupas:
  https://vedicpupil.in/library/brihat-parashara-hora-shastra-book-by-parashara/spashtabal-ch27/9
- Astronomy Engine official HourAngle API/release documentation, used only to
  obtain observer-specific apparent Sun hour angle from the pinned offline
  ephemeris rather than approximating it from civil clock time:
  https://github.com/cosinekitty/astronomy/releases
- BPHS Chapter 27 verses 10-11 two-source translations for Paksha Bala, including
  the folded Sun-Moon separation divided by 3 for the benefic group and the
  60-virupa complement for the malefic group:
  https://vedicpupil.in/library/brihat-parashara-hora-shastra-book-by-parashara/spashtabal-ch27/10
  https://vedicpupil.in/library/brihat-parashara-hora-shastra-book-by-parashara/spashtabal-ch27/11
- BPHS Chapter 27 verses 15-17 two-source translations for Ayana Bala and the
  45/33/12 khanda method from tropical longitude:
  https://vedicpupil.in/library/brihat-parashara-hora-shastra-book-by-parashara/spashtabal-ch27/15
  https://vedicpupil.in/library/brihat-parashara-hora-shastra-book-by-parashara/spashtabal-ch27/16
  https://vedicpupil.in/library/brihat-parashara-hora-shastra-book-by-parashara/spashtabal-ch27/17
- Saravali open documentation cross-check for the Parashara 45/33/12 interpolation
  and its published tropical-longitude examples:
  https://saravali.github.io/astrology/bala_ayana.html
- BPHS Chapter 27 verses 18 and 21-25 for Cheshta Bala: direct Sun=Ayana and
  Moon=Paksha equivalences, the eight motional labels/virupa values, and the
  separate mean/true-longitude Cheshta-kendra method:
  https://enjoylearningsanskrit.com/scriptures/parashara/chapter-27/
- Saravali open documentation for the operational motion-state speed bands used
  by `bphsMotionStateSpeedProfileV1` and the sign-entry distinction for
  Anuvakra/Atichara:
  https://saravali.github.io/astrology/bala_cheshta.html
- AstrologySoftware reference table for governed nominal mean daily motions used
  only to normalize the v1 speed-state operational profile:
  https://astrologysoftware.com/m/community/learn/dictionary/average_daily_motion.html
- BPHS Chapter 27 strength translation/cross-check including Uchcha, Kendradi,
  Drekkana and Dig Bala formulas:
  https://jyotishvidya.com/ch27.htm
- BPHS Chapter 27 verse 20 for Yuddha Bala gain/loss: the pre-war strength difference is added to the victor and deducted from the vanquished:
  https://vedicpupil.in/library/brihat-parashara-hora-shastra-book-by-parashara/spashtabal-ch27/20
- BPHS 27.32-33 required Shadbala totals cross-checked in AstroCentral's source-variant note: Sun 390, Moon 360, Mars 300, Mercury 420, Jupiter 390, Venus 330 and Saturn 300 virupas; 1 Rupa = 60 virupas:
  https://astrocentral.com/articles/shadbala-calculation-usage
- Cross-check for the traditional northern/ecliptic-latitude victor criterion in close planetary war; ASTRO LOGIC versions this separately from the BPHS gain/loss formula:
  https://www.sanatanveda.com/astrology/planetary-war-in-astrology/
- Predictive Astrology Through the Nirayana System, Part II, Shadbala section,
  used to document the implementation disagreement over whether Tatkalika
  friendship is Rasi-based or recalculated in the underlying varga:
  https://ftpmirror.your.org/pub/wikimedia/images/wikipedia/commons/0/01/PREDICTIVE-NIRAYANA-SIDEREAL-ASTROLOGY_-_PART_II_AS-TAUGHT-BY-PROF-ANTHONY-WRITER.pdf

The v6 profile retains the earlier Saptavargaja points: Moolatrikona 45, own sign 30, great friend 20,
friend 15, neutral 10, enemy 4 and great enemy 2 virupas across D1, D2, D3, D7,
D9, D12 and D30. The BPHS 27.6 Drekkana profile used here assigns the
first decanate to male planets (Sun/Mars/Jupiter), the second to female planets
(Moon/Venus), and the third to hermaphrodite planets (Mercury/Saturn); common
alternative orderings are not silently mixed into v6. ASTRO LOGIC explicitly retains the Rasi-position-based Tatkalika
Maitri for this version; the alternative underlying-varga method is not mixed
into the same snapshot. Rahu/Ketu are excluded from the seven-planet Shadbala
profile.

Foundation v10 publishes Sthana Bala, Dig Bala, Nathonnata Bala, Paksha Bala, Tribhaga Bala, Varsha Bala, Masa Bala, Dina Bala, Hora Bala, Ayana Bala, governed Cheshta Bala, Naisargika Bala and Drik Bala. Dig Bala uses exact sidereal planet and Ascendant longitudes: Sun/Mars measure from the 4th-direction zero point, Jupiter/Mercury from the 7th, Moon/Venus from the 10th and Saturn from Lagna; the angular difference is folded to at most 180 degrees and divided by 3, yielding 0..60 virupas. Paksha Bala follows BPHS 27.10-11 without silently applying later Moon-doubling conventions: the folded Sun-Moon separation divided by 3 is assigned to Moon/Mercury/Jupiter/Venus and its 60-complement to Sun/Mars/Saturn. Ayana Bala follows BPHS 27.15-17 from tropical longitude using the 45/33/12 khanda interpolation and the text's planet-group north/south adjustment.

Nathonnata v1 follows BPHS 27.9. Current `vedic-chart-v9` persists the observer-specific apparent Sun hour angle from Astronomy Engine. The absolute distance of that hour angle from apparent midnight (12h) is converted from hours to ghatis (2.5 ghatis/hour), subtracted from 30 to obtain Nata, and doubled for Moon/Mars/Saturn; Sun/Jupiter/Venus receive the 60-virupa complement and Mercury always receives 60. Legacy v1-v5 outputs leave Nathonnata unavailable rather than approximating apparent time from civil time.

For Cheshta, BPHS 27.18 is applied directly to Sun (Ayana Bala) and Moon (Paksha Bala). For Mars through Saturn, current `vedic-chart-v9` persists exact daily longitude speed. `bphsMotionStateSpeedProfileV1` operationalizes the BPHS eight-state virupa table with Saravali speed bands normalized by governed mean daily motions and a one-day sign-entry projection: Vakra 60, Anuvakra 30, Vikala 15, Mandatara 15, Manda 30, Sama 7.5, Chara 45 and Atichara 30. This is deliberately labelled an operational speed-state profile and is **not** claimed to be the alternative BPHS 27.24-25 mean/true-longitude Cheshta-kendra algorithm. Legacy v1-v4 outputs that do not persist speed leave Mars-Saturn Cheshta unavailable rather than estimating it from the retrograde flag.

Tribhaga v1 follows BPHS 27.12 using the cross-checked classical ordering: Mercury/Sun/Saturn for the first/second/third thirds of daylight, Moon/Venus/Mars for the first/second/third thirds of night, while Jupiter receives 60 virupas at all times. Current `vedic-chart-v9` obtains actual sunrise/set events from the pinned Astronomy Engine `Astronomy_SearchRiseSet` API, selects the solar period that brackets the birth instant, splits that exact interval into three equal durations, and persists the period kind, third and UTC boundaries. It does not substitute civil-clock 8-hour blocks. If rise/set search is unavailable, such as polar day/night, Tribhaga remains null.

Varsha-Masa-Dina-Hora v1 follows BPHS 27.13 for the strength amounts: 15/30/45/60 virupas to the Varsha, Masa, Dina and Hora lords respectively. The versioned `siderealSolarIngressAstrologicalDayV1` operational profile anchors Varsha to the prior sidereal Aries ingress and Masa to the prior ingress into the Sun's current sidereal sign, assigns the weekday lord of the sunrise-based astrological day containing each ingress, assigns Dina from the current sunrise-to-sunrise astrological day, and derives Hora from twelve equal daylight plus twelve equal night seasonal horas using the Chaldean Saturn-Jupiter-Mars-Sun-Venus-Mercury-Moon sequence from the Dina lord. Calendar weekday conversion uses the recorded birth UTC offset because the current input schema has no IANA zone id; that limitation is persisted/documented rather than hidden. If required solar events are unavailable, the affected values remain null.

The stored pre-war Kala subtotal is Nathonnata + Paksha + Tribhaga + Varsha + Masa + Dina + Hora + Ayana where current v9 context is available. Yuddha v1 applies BPHS 27.20 to Mars, Mercury, Jupiter, Venus and Saturn when an isolated same-sign pair lies within 1 degree: the versioned operational profile uses persisted geocentric ecliptic latitude to identify the northern participant as computational victor, then adds the absolute pre-war sixfold-strength difference to the victor and subtracts it from the loser. No-war is a computed zero; multi-war clusters, latitude ties, missing latitude and incomplete pre-war strength remain gated. Complete Kala may therefore be available on v9. Foundation v10 sums Sthana + Dig + Kala + Cheshta + Naisargika + Drik only when every family is available, converts Virupas to Rupas by dividing by 60, and compares the total with the BPHS 27.32-33 planet-specific required total. The stored ratio and surplus/deficit are quantitative strength sufficiency only; no benefic/malefic polarity, guaranteed event or automatic remedy is inferred from crossing the threshold.


## Ashtakavarga foundation source profile v3

- BPHS Chapters 66-72 notation, eight-reference structure, seven-table aggregate and BPHS-72 SAV bands cross-checked here:
  https://astrocentral.com/articles/ashtakavarga-concept
- Received-standard seven-planet benefic-place tables and B.V. Raman standard-horoscope distribution cross-check:
  https://vedastro.org/blog/Mastering-Ashtakavarga-Part-2-Building-Bhinnashtakavarga-Charts.html
- Secondary calculator note documenting lineage/recension table differences and the fixed 48/49/39/54/56/52/39 totals:
  https://desiutils.in/astrology/ashtakavarga-calculator

ASTRO LOGIC v1 stores the binary beneficial value as `positiveMarks` instead of silently choosing the word Bindu or Rekha, because the local BPHS convention described by AstroCentral calls auspicious `1` Rekha/Sthana while much modern software calls the same positive score a Bindu. The selected rule table is the received-standard Parashari/B.V.-Raman-style table reproduced by VedAstro; known lineage/recension differences are not blended. The engine checks each BAV fixed total and the 337-point unreduced SAV total. BPHS-72 comparative bands are used for whole-sign house support (>30 favourable, 25-30 medium, <25 adverse), but v1 does not convert those scores into guaranteed events. Foundation v3 preserves those unreduced scores, carries the separate reduction profile below, and adds the post-Shodhana Pinda profile documented next. Timing v2 still consumes the unreduced scores without modifying the underlying tables.


## Ashtakavarga Trikona/Ekadhipatya reduction source profile v1

- BPHS Chapter 67 Trikona Shodhana and its zero/all-equal edge cases are cross-checked against the Chapter 67-68 translation reproduced here:
  https://pdfcoffee.com/secrets-of-ashtakvarga-dhilip-kumardocx-pdf-free.html
- A modern source audit separating raw aggregate bands from reduced later-stage values and summarizing BPHS Chapters 67-68 is here:
  https://astrocentral.com/articles/ashtakavarga-reading

The governed reduction order is Trikona first, Ekadhipatya second. Trikona uses Aries-Leo-Sagittarius, Taurus-Virgo-Capricorn, Gemini-Libra-Aquarius and Cancer-Scorpio-Pisces. If any member already has zero positive marks the group is unchanged; if all three nonzero values are equal all three become zero; otherwise the minimum is subtracted from all three. Ekadhipatya is then applied to Aries/Scorpio, Gemini/Virgo, Sagittarius/Pisces, Taurus/Libra and Capricorn/Aquarius. If either paired value is zero there is no reduction; both occupied signs are unchanged; both empty unequal signs become the smaller value; both empty equal signs become zero; with exactly one occupied sign the occupied value stays, while the empty value becomes the difference when the occupied value is smaller and otherwise becomes zero. Sun and Moon own one sign and are not Ekadhipatya pairs.

The checked passage refers to planets occupying signs but does not establish a node-specific occupancy rule for this reduction profile. ASTRO LOGIC v1 therefore uses D1 occupancy from Sun through Saturn only and excludes Rahu/Ketu from the reduction decision. This is recorded as a versioned implementation convention, not presented as universal doctrine. Reduced aggregate values are stored for audit only; the BPHS-72 raw SAV >30 / 25-30 / <25 classification is not applied to them. Pinda Sadhana is implemented as the separate profile below; Kaksha and reduced/Pinda timing remain future profiles.


## Ashtakavarga post-Shodhana Pinda source profile v1

- Phaladeepika Chapter 24, verses 23-26, gives the post-reduction Rashi and Graha multiplier method and the fixed factors: https://www.wisdomlib.org/hinduism/book/phaladeepika-by-mantreswara-text-and-translation/d/doc1621596.html
- M.S. Mehta, *Ashtakavarga*, Chapter IV, independently reproduces the same Rashi/Graha multiplier tables and explicitly names Rashi Pinda + Graha Pinda = Shodhya Pinda: https://pdfcoffee.com/ms-mehta-ashtakavargha-2002doc-pdf-free.html

`ashtakavarga-pinda-v1` consumes only the Ekadhipatya-reduced BAV. Rashi multipliers by Aries through Pisces are 7,10,8,4,10,5,7,8,9,5,11,12. Graha multipliers are Sun 5, Moon 5, Mars 8, Mercury 5, Jupiter 10, Venus 7 and Saturn 5. For each target BAV, Rashi Pinda is the sum of reduced sign marks multiplied by the twelve Rashi factors. Graha Pinda separately reads that same target BAV at the D1 signs occupied by Sun through Saturn and multiplies those marks by the corresponding Graha factors. Shodhya/Yoga Pinda is the sum of the two. The engine persists every contribution and validates the total identity. Pinda is not yet converted into a timing promise, longevity claim, or remedy recommendation.


## Ashtakavarga transit-confirmation source profile v1

- Saravali, Chapters 53-54, documents Ashtakavarga as a transit-oriented system and gives progressively stronger results as the positive-point count rises; an accessible translation is hosted here:
  https://saravali.blogspot.com/
- A modern cross-check of the common operational BAV transit grouping (5-8 favourable/supportive, 4 mixed/average, 0-3 challenging) is documented here:
  https://www.prokerala.com/astrology/ashtakavarga.php
- BPHS Ashtakavarga's purpose as a transit-based method and its eight-reference binary structure are summarized here:
  https://saravali.github.io/astrology/ashtakavarga.html

ASTRO LOGIC stores beneficial binary values as `positiveMarks`, so the v1 timing profile interprets 5-8 positive marks as supportive, 4 as Mixed and 0-3 as challenging for the transiting planet's own unreduced BAV. The transit sign's existing SAV band is used only as a context gate: BAV and SAV must agree directionally before the Ashtakavarga timing family emits a supportive/challenging signal. This strict agreement rule is an ASTRO LOGIC governance policy designed to prevent one score from overriding contradictory evidence. It is not presented as a universal classical formula. Rahu/Ketu have no v1 BAV tables and remain excluded. Trikona/Ekadhipatya reductions and Shodhana Pinda/Yoga Pinda are persisted calculation stages. Kaksha timing is now governed separately below; Pinda-derived timing and broader exact-degree/nakshatra triggers remain future profiles.


## Ashtakavarga Kaksha transit micro-zone source profile v1

- Modern Ashtakavarga references consistently describe each 30° sign as eight equal Kaksha zones of 3°45′ in the order Saturn, Jupiter, Mars, Sun, Venus, Mercury, Moon, Lagna and use the active contributor in the transiting planet's BAV to refine transit support: https://vedastro.org/blog/Mastering-Ashtakavarga-Part-15-Transits-Gochara.html
- Independent implementation-oriented cross-check: https://pomantra.com/ashtakavarga/

ASTRO LOGIC v1 uses half-open intervals [0,3.75), [3.75,7.5), ... [26.25,30). The active Kaksha lord is checked directly against the contributor list already persisted for the transiting planet's unreduced BAV sign. Presence is supportive and absence is challenging at the micro-zone layer. This Kaksha signal does not override contradictory whole-sign BAV/SAV evidence: Question Timing v3 emits a directional Ashtakavarga family only when the whole-sign BAV+SAV direction and the active Kaksha agree. This strict agreement gate is an ASTRO LOGIC governance rule, not presented as a universal classical formula.


## Dashamsa (D10) source profile v1

- Brihat Parashara Hora Shastra, divisional-chart verses 13-14: a sign is divided into ten 3-degree Dashamsas; for an odd sign counting begins from the same sign, while for an even sign it begins from the ninth sign. Accessible translation/table: https://www.horasad.com/download/ebooks/BRIHAT_PARASHARA_HORA_SHASTRA_1.pdf
- Independent text quotation/cross-check of the same BPHS verses: https://www.ask-oracle.com/divisional-charts/d10/

ASTRO LOGIC persists this as `bphs-dashamsa-odd-self-even-ninth-v1`. D10 interpretation is deliberately conservative: the app reads the explicit D10 Ascendant, house lords, classical occupants and the already-enabled Parashari full-sign aspect profile, then cross-checks the D1 tenth lord with the D10 tenth house. The interpretation method is a governed application profile; it is not presented as a verse-by-verse classical prediction formula. Rahu/Ketu remain occupancy-only in v1.

## Advanced Yoga/Dosha source profile v1

- BPHS Chapters 39 and 41 (Raja-Yoga relationships and the enabled great-affluence/Dhana formulas):
  https://sanskritdocuments.org/doc_z_misc_sociology_astrology/parasharhorasaram.html
- Phaladeepika Chapter 6 (ninth/tenth-lord Raja-Yoga wording and Harsha/Sarala/Vimala profiles):
  https://www.wisdomlib.org/hinduism/book/phaladeepika-by-mantreswara-text-and-translation/d/doc1621376.html
- Phaladeepika Chapter 7 (Neecha-bhanga/Raja-Yoga cancellation conditions):
  https://www.wisdomlib.org/hinduism/book/phaladeepika-by-mantreswara-text-and-translation/d/doc1621381.html

`advanced-yoga-dosha-v1` intentionally implements a bounded subset rather than a broad keyword catalog. The enabled Raja-Yoga layer recognizes the ninth/tenth-lord conjunction only when it occurs in the v1 auspicious-house set and a same-sign-conjunction subset of selected Kendra/Kona lord relationships. Other conjunction placements are retained only as candidates where the cited verse requires an auspicious Bhava. Exchange, every possible mutual aspect, and every lineage-specific sambandha are not silently treated as equivalent.

The Dhana layer implements the explicit BPHS Chapter 41 verses 2-8 sign/house formulas as separate rule ids and retains the text's instruction to assess the participating planets' condition. ASTRO LOGIC's debilitation/combustion/same-sign-node `participant weakening` flag is a transparent operational review layer, not claimed to be a universal classical cancellation formula.

For Vipareeta review, the sixth/eighth/twelfth lords occupying 6/8/12 are labelled Harsha/Sarala/Vimala structural profiles following the enabled Phaladeepika VI.57 reading. Dual-house lordship is kept visible as context and never silently cancels or guarantees reversal of adversity.

Neecha-bhanga v1 checks only the enabled Phaladeepika VII.27-29 conditions: the debilitation-sign lord in a Kendra from Lagna/Moon, the exaltation-sign lord in a Kendra from Lagna/Moon, those two lords in mutual Kendras, and the occupied-sign lord's enabled full-sign aspect to the debilitated planet. A match remains `Mixed`; natal debilitation remains in the evidence and the planet is not automatically relabelled strong or benefic.

Kuja review remains an ASTRO LOGIC governed compatibility screen rather than a deterministic classical verdict. It checks Mars from Lagna, Moon and Venus; keeps house 2 as a separately labelled extension; and records D1/D9 dignity and Jupiter conjunction/full-sign-aspect as possible mitigation evidence. No mitigation is automatic cancellation, and the rule cannot by itself predict divorce, injury, abuse, spouse harm or death. Cross-Yoga synthesis preserves contradictions and is capped at Medium confidence.

## Rahu/Ketu natal, Dasha and transit profile

- **Phaladeepika VIII.25-34**: Rahu and Ketu house-by-house natal effects; VIII.34 also states the traditional analogy Rahu-like-Saturn and Ketu-like-Mars. ASTRO LOGIC paraphrases these themes and does not preserve high-stakes literal predictions.
- **Phaladeepika XX.39**: Rahu gives effects according to the nature of the planet with which it is associated. v1 applies this only to explicit same-sign classical association and preserves opposing carrier directions as Mixed. The exact statement is not extended to Ketu.
- **Phaladeepika XX.52-53**: Rahu/Ketu Kendra/Trikona connection and benefic-sign association are enabled as Medium-capped candidates. v1 uses same-sign conjunction as the explicit connection convention; Moon-owned benefic-sign status is conditional on waxing phase in natal review and is gated in the Dasha helper.
- **Phaladeepika XXVI.24**: Rahu's transit through the twelve houses from the natal Moon is directionalized conservatively as supportive in 3/6/10/11 and challenging in 1/2/4/5/7/8/9/12. Literal sickness/death language is not emitted. No equivalent Ketu transit rule is enabled in v1.

Rahu/Ketu exaltation/debilitation, special aspects and other practitioner-specific node doctrines remain explicitly outside this profile.

## Remedy Recommendation application-safety profile v1

The behavioural remedy layer in `vedic-remedy-recommendation-v1` is explicitly
an ASTRO LOGIC application-safety policy, not a claim that practical behaviour
is a quoted classical Jyotisha remedy. It is triggered only after two distinct
chart-rule evidence ids independently show a challenging tendency in the same
actionable life area. Supportive/mixed evidence never triggers it, and longevity
or death-related remedy automation is excluded.

The project retains the R. Santhanam BPHS archive as a textual reference:
https://archive.org/stream/BPHSEnglish/BPHS%20-%201%20RSanthanam_djvu.txt

Published BPHS editions and authenticity discussions vary around later remedial
chapters, and gemstone-as-remedy rules are especially inconsistent across
practice lineages. Therefore v1 does not attribute a universal mantra, charity,
ritual or gemstone prescription to BPHS. Mantra, charity and ritual families remain disabled. Gemstone strengthening review is handled only by the later `vedic-gemstone-candidate-v1` application profile, which does not claim a universal BPHS prescription.


## Gemstone Candidate & Contraindication application profile v1

`vedic-gemstone-candidate-v1` is an ASTRO LOGIC strengthening-screen policy, not a claim that one universal gemstone doctrine is stated in BPHS. The planet-to-gem labels are kept in the explicit operational profile `astro-logic-navaratna-mapping-v1` for practitioner review and can be versioned independently if the project adopts a different lineage.

The eligibility gate intentionally combines already-governed evidence families rather than inventing a new planetary-strength formula: ascendant-specific functional ownership, D1/D9 dignity, complete Shadbala and BPHS 27.32-33 required-strength ratio, combustion, BPHS 27.20 Yuddha state, same-sign Rahu/Ketu contact, and the Mahadasha/Antardasha window active at the immutable calculation-analysis instant. A functionally challenging score (<= -2) is a v1 strengthening contraindication. Supportive functional role plus a verified Shadbala deficit and active Dasha relevance can become `eligible` only if node-contact and unresolved-war gates are absent. All other non-contraindicated states remain `insufficientEvidence`.

`eligible` means eligible for professional review only. It never approves a gemstone, dose/weight, metal, finger, wearing day, ritual, substitute, medical treatment, financial outcome or guaranteed astrological result. Rahu/Ketu gemstone automation remains outside v1 because the current complete Shadbala contract applies to the seven classical planets and node-strengthening doctrines are not unified in the enabled source profile.

## Western Astrology Foundation v1 (v081)

Western rules are governed separately in `WESTERN_RULE_SOURCES.md`. v081 uses tropical geocentric positions, explicit Placidus/Whole Sign/Equal house profiles, the five major aspects with a versioned ASTRO LOGIC orb profile, and traditional seven-planet domicile/exaltation/detriment/fall evidence. Western output is not treated as independent confirmation of Vedic/KP evidence and does not generate automatic event predictions.
