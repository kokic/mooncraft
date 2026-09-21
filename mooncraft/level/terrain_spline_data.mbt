// Generated from Mojang Java 1.18.2 worldgen report, terrain_shaper.
// Regenerate with analysis/terrain/generate_splines.py; do not tune this table.

///|
let terrain_spline_0 : TerrainSpline = Curve(Ridges, [
  (-1.0, Constant(-0.08880186), 0.38940096),
  (1.0, Constant(0.69000006), 0.38940096),
])

///|
let terrain_spline_1 : TerrainSpline = Curve(Ridges, [
  (-1.0, Constant(-0.115760356), 0.37788022),
  (1.0, Constant(0.6400001), 0.37788022),
])

///|
let terrain_spline_2 : TerrainSpline = Curve(Ridges, [
  (-1.0, Constant(-0.2222), 0.0),
  (-0.75, Constant(-0.2222), 0.0),
  (-0.65, Constant(0.0), 0.0),
  (0.5954547, Constant(2.9802322e-08), 0.0),
  (0.6054547, Constant(2.9802322e-08), 0.2534563),
  (1.0, Constant(0.100000024), 0.2534563),
])

///|
let terrain_spline_3 : TerrainSpline = Curve(Ridges, [
  (-1.0, Constant(-0.3), 0.5),
  (-0.4, Constant(0.05), 0.0),
  (0.0, Constant(0.05), 0.0),
  (0.4, Constant(0.05), 0.0),
  (1.0, Constant(0.060000002), 0.007000001),
])

///|
let terrain_spline_4 : TerrainSpline = Curve(Ridges, [
  (-1.0, Constant(-0.15), 0.5),
  (-0.4, Constant(0.0), 0.0),
  (0.0, Constant(0.0), 0.0),
  (0.4, Constant(0.05), 0.1),
  (1.0, Constant(0.060000002), 0.007000001),
])

///|
let terrain_spline_5 : TerrainSpline = Curve(Ridges, [
  (-1.0, Constant(-0.15), 0.5),
  (-0.4, Constant(0.0), 0.0),
  (0.0, Constant(0.0), 0.0),
  (0.4, Constant(0.0), 0.0),
  (1.0, Constant(0.0), 0.0),
])

///|
let terrain_spline_6 : TerrainSpline = Curve(Ridges, [
  (-1.0, Constant(-0.02), 0.0),
  (-0.4, Constant(-0.03), 0.0),
  (0.0, Constant(-0.03), 0.0),
  (0.4, Constant(0.0), 0.06),
  (1.0, Constant(0.0), 0.0),
])

///|
let terrain_spline_7 : TerrainSpline = Curve(Erosion, [
  (-0.85, terrain_spline_0, 0.0),
  (-0.7, terrain_spline_1, 0.0),
  (-0.4, terrain_spline_2, 0.0),
  (-0.35, terrain_spline_3, 0.0),
  (-0.1, terrain_spline_4, 0.0),
  (0.2, terrain_spline_5, 0.0),
  (0.7, terrain_spline_6, 0.0),
])

///|
let terrain_spline_8 : TerrainSpline = Curve(Ridges, [
  (-1.0, Constant(-0.25), 0.5),
  (-0.4, Constant(0.05), 0.0),
  (0.0, Constant(0.05), 0.0),
  (0.4, Constant(0.05), 0.0),
  (1.0, Constant(0.060000002), 0.007000001),
])

///|
let terrain_spline_9 : TerrainSpline = Curve(Ridges, [
  (-1.0, Constant(-0.1), 0.5),
  (-0.4, Constant(0.001), 0.01),
  (0.0, Constant(0.003), 0.01),
  (0.4, Constant(0.05), 0.094000004),
  (1.0, Constant(0.060000002), 0.007000001),
])

///|
let terrain_spline_10 : TerrainSpline = Curve(Ridges, [
  (-1.0, Constant(-0.1), 0.5),
  (-0.4, Constant(0.01), 0.0),
  (0.0, Constant(0.01), 0.0),
  (0.4, Constant(0.03), 0.04),
  (1.0, Constant(0.1), 0.049),
])

///|
let terrain_spline_11 : TerrainSpline = Curve(Ridges, [
  (-1.0, Constant(-0.02), 0.0),
  (-0.4, Constant(-0.03), 0.0),
  (0.0, Constant(-0.03), 0.0),
  (0.4, Constant(0.03), 0.12),
  (1.0, Constant(0.1), 0.049),
])

///|
let terrain_spline_12 : TerrainSpline = Curve(Erosion, [
  (-0.85, terrain_spline_0, 0.0),
  (-0.7, terrain_spline_1, 0.0),
  (-0.4, terrain_spline_2, 0.0),
  (-0.35, terrain_spline_8, 0.0),
  (-0.1, terrain_spline_9, 0.0),
  (0.2, terrain_spline_10, 0.0),
  (0.7, terrain_spline_11, 0.0),
])

///|
let terrain_spline_13 : TerrainSpline = Curve(Ridges, [
  (-1.0, Constant(0.20235021), 0.0),
  (0.0, Constant(0.7161751), 0.5138249),
  (1.0, Constant(1.23), 0.5138249),
])

///|
let terrain_spline_14 : TerrainSpline = Curve(Ridges, [
  (-1.0, Constant(0.2), 0.0),
  (0.0, Constant(0.44682026), 0.43317974),
  (1.0, Constant(0.88), 0.43317974),
])

///|
let terrain_spline_15 : TerrainSpline = Curve(Ridges, [
  (-1.0, Constant(0.2), 0.0),
  (0.0, Constant(0.30829495), 0.3917051),
  (1.0, Constant(0.70000005), 0.3917051),
])

///|
let terrain_spline_16 : TerrainSpline = Curve(Ridges, [
  (-1.0, Constant(-0.25), 0.5),
  (-0.4, Constant(0.35), 0.0),
  (0.0, Constant(0.35), 0.0),
  (0.4, Constant(0.35), 0.0),
  (1.0, Constant(0.42000002), 0.049000014),
])

///|
let terrain_spline_17 : TerrainSpline = Curve(Ridges, [
  (-1.0, Constant(-0.1), 0.5),
  (-0.4, Constant(0.0069999998), 0.07),
  (0.0, Constant(0.021), 0.07),
  (0.4, Constant(0.35), 0.658),
  (1.0, Constant(0.42000002), 0.049000014),
])

///|
let terrain_spline_18 : TerrainSpline = Curve(Ridges, [
  (-1.0, Constant(-0.1), 0.0),
  (-0.4, terrain_spline_10, 0.0),
  (0.0, Constant(0.17), 0.0),
])

///|
let terrain_spline_19 : TerrainSpline = Curve(Erosion, [
  (-0.85, terrain_spline_13, 0.0),
  (-0.7, terrain_spline_14, 0.0),
  (-0.4, terrain_spline_15, 0.0),
  (-0.35, terrain_spline_16, 0.0),
  (-0.1, terrain_spline_17, 0.0),
  (0.2, terrain_spline_10, 0.0),
  (0.4, terrain_spline_10, 0.0),
  (0.45, terrain_spline_18, 0.0),
  (0.55, terrain_spline_18, 0.0),
  (0.58, terrain_spline_10, 0.0),
  (0.7, terrain_spline_11, 0.0),
])

///|
let terrain_spline_20 : TerrainSpline = Curve(Ridges, [
  (-1.0, Constant(0.34792626), 0.0),
  (0.0, Constant(0.9239631), 0.5760369),
  (1.0, Constant(1.5), 0.5760369),
])

///|
let terrain_spline_21 : TerrainSpline = Curve(Ridges, [
  (-1.0, Constant(0.2), 0.0),
  (0.0, Constant(0.5391705), 0.4608295),
  (1.0, Constant(1.0), 0.4608295),
])

///|
let terrain_spline_22 : TerrainSpline = Curve(Ridges, [
  (-1.0, Constant(-0.2), 0.5),
  (-0.4, Constant(0.5), 0.0),
  (0.0, Constant(0.5), 0.0),
  (0.4, Constant(0.5), 0.0),
  (1.0, Constant(0.6), 0.070000015),
])

///|
let terrain_spline_23 : TerrainSpline = Curve(Ridges, [
  (-1.0, Constant(-0.05), 0.5),
  (-0.4, Constant(0.01), 0.099999994),
  (0.0, Constant(0.03), 0.099999994),
  (0.4, Constant(0.5), 0.94),
  (1.0, Constant(0.6), 0.070000015),
])

///|
let terrain_spline_24 : TerrainSpline = Curve(Ridges, [
  (-1.0, Constant(-0.05), 0.5),
  (-0.4, Constant(0.01), 0.0),
  (0.0, Constant(0.01), 0.0),
  (0.4, Constant(0.03), 0.04),
  (1.0, Constant(0.1), 0.049),
])

///|
let terrain_spline_25 : TerrainSpline = Curve(Ridges, [
  (-1.0, Constant(-0.05), 0.0),
  (-0.4, terrain_spline_24, 0.0),
  (0.0, Constant(0.17), 0.0),
])

///|
let terrain_spline_26 : TerrainSpline = Curve(Ridges, [
  (-1.0, Constant(-0.02), 0.015),
  (-0.4, Constant(0.01), 0.0),
  (0.0, Constant(0.01), 0.0),
  (0.4, Constant(0.03), 0.04),
  (1.0, Constant(0.1), 0.049),
])

///|
let terrain_spline_27 : TerrainSpline = Curve(Erosion, [
  (-0.85, terrain_spline_20, 0.0),
  (-0.7, terrain_spline_21, 0.0),
  (-0.4, terrain_spline_21, 0.0),
  (-0.35, terrain_spline_22, 0.0),
  (-0.1, terrain_spline_23, 0.0),
  (0.2, terrain_spline_24, 0.0),
  (0.4, terrain_spline_24, 0.0),
  (0.45, terrain_spline_25, 0.0),
  (0.55, terrain_spline_25, 0.0),
  (0.58, terrain_spline_24, 0.0),
  (0.7, terrain_spline_26, 0.0),
])

///|
let terrain_spline_28 : TerrainSpline = Curve(Continents, [
  (-1.1, Constant(0.044), 0.0),
  (-1.02, Constant(-0.2222), 0.0),
  (-0.51, Constant(-0.2222), 0.0),
  (-0.44, Constant(-0.12), 0.0),
  (-0.18, Constant(-0.12), 0.0),
  (-0.16, terrain_spline_7, 0.0),
  (-0.15, terrain_spline_7, 0.0),
  (-0.1, terrain_spline_12, 0.0),
  (0.25, terrain_spline_19, 0.0),
  (1.0, terrain_spline_27, 0.0),
])

///|
let terrain_spline_29 : TerrainSpline = Curve(Weirdness, [
  (-0.2, Constant(6.3), 0.0),
  (0.2, Constant(6.25), 0.0),
])

///|
let terrain_spline_30 : TerrainSpline = Curve(Weirdness, [
  (-0.05, Constant(6.3), 0.0),
  (0.05, Constant(2.67), 0.0),
])

///|
let terrain_spline_31 : TerrainSpline = Curve(Weirdness, [
  (-0.05, Constant(2.67), 0.0),
  (0.05, Constant(6.3), 0.0),
])

///|
let terrain_spline_32 : TerrainSpline = Curve(Weirdness, [
  (0.0, Constant(6.25), 0.0),
  (0.1, Constant(0.625), 0.0),
])

///|
let terrain_spline_33 : TerrainSpline = Curve(Ridges, [
  (-0.9, Constant(6.25), 0.0),
  (-0.69, terrain_spline_32, 0.0),
])

///|
let terrain_spline_34 : TerrainSpline = Curve(Erosion, [
  (-0.6, terrain_spline_29, 0.0),
  (-0.5, terrain_spline_30, 0.0),
  (-0.35, terrain_spline_29, 0.0),
  (-0.25, terrain_spline_29, 0.0),
  (-0.1, terrain_spline_31, 0.0),
  (0.03, terrain_spline_29, 0.0),
  (0.35, Constant(6.25), 0.0),
  (0.45, terrain_spline_33, 0.0),
  (0.55, terrain_spline_33, 0.0),
  (0.62, Constant(6.25), 0.0),
])

///|
let terrain_spline_35 : TerrainSpline = Curve(Weirdness, [
  (-0.2, Constant(6.3), 0.0),
  (0.2, Constant(5.47), 0.0),
])

///|
let terrain_spline_36 : TerrainSpline = Curve(Weirdness, [
  (0.0, Constant(5.47), 0.0),
  (0.1, Constant(0.625), 0.0),
])

///|
let terrain_spline_37 : TerrainSpline = Curve(Ridges, [
  (-0.9, Constant(5.47), 0.0),
  (-0.69, terrain_spline_36, 0.0),
])

///|
let terrain_spline_38 : TerrainSpline = Curve(Erosion, [
  (-0.6, terrain_spline_35, 0.0),
  (-0.5, terrain_spline_30, 0.0),
  (-0.35, terrain_spline_35, 0.0),
  (-0.25, terrain_spline_35, 0.0),
  (-0.1, terrain_spline_31, 0.0),
  (0.03, terrain_spline_35, 0.0),
  (0.35, Constant(5.47), 0.0),
  (0.45, terrain_spline_37, 0.0),
  (0.55, terrain_spline_37, 0.0),
  (0.62, Constant(5.47), 0.0),
])

///|
let terrain_spline_39 : TerrainSpline = Curve(Weirdness, [
  (-0.2, Constant(6.3), 0.0),
  (0.2, Constant(5.08), 0.0),
])

///|
let terrain_spline_40 : TerrainSpline = Curve(Weirdness, [
  (0.0, Constant(5.08), 0.0),
  (0.1, Constant(0.625), 0.0),
])

///|
let terrain_spline_41 : TerrainSpline = Curve(Ridges, [
  (-0.9, Constant(5.08), 0.0),
  (-0.69, terrain_spline_40, 0.0),
])

///|
let terrain_spline_42 : TerrainSpline = Curve(Erosion, [
  (-0.6, terrain_spline_39, 0.0),
  (-0.5, terrain_spline_30, 0.0),
  (-0.35, terrain_spline_39, 0.0),
  (-0.25, terrain_spline_39, 0.0),
  (-0.1, terrain_spline_31, 0.0),
  (0.03, terrain_spline_39, 0.0),
  (0.35, Constant(5.08), 0.0),
  (0.45, terrain_spline_41, 0.0),
  (0.55, terrain_spline_41, 0.0),
  (0.62, Constant(5.08), 0.0),
])

///|
let terrain_spline_43 : TerrainSpline = Curve(Weirdness, [
  (-0.2, Constant(6.3), 0.0),
  (0.2, Constant(4.69), 0.0),
])

///|
let terrain_spline_44 : TerrainSpline = Curve(Ridges, [
  (0.45, terrain_spline_43, 0.0),
  (0.7, Constant(1.56), 0.0),
])

///|
let terrain_spline_45 : TerrainSpline = Curve(Ridges, [
  (-0.7, terrain_spline_43, 0.0),
  (-0.15, Constant(1.37), 0.0),
])

///|
let terrain_spline_46 : TerrainSpline = Curve(Erosion, [
  (-0.6, terrain_spline_43, 0.0),
  (-0.5, terrain_spline_30, 0.0),
  (-0.35, terrain_spline_43, 0.0),
  (-0.25, terrain_spline_43, 0.0),
  (-0.1, terrain_spline_31, 0.0),
  (0.03, terrain_spline_43, 0.0),
  (0.05, terrain_spline_44, 0.0),
  (0.4, terrain_spline_44, 0.0),
  (0.45, terrain_spline_45, 0.0),
  (0.55, terrain_spline_45, 0.0),
  (0.58, Constant(4.69), 0.0),
])

///|
let terrain_spline_47 : TerrainSpline = Curve(Continents, [
  (-0.19, Constant(3.95), 0.0),
  (-0.15, terrain_spline_34, 0.0),
  (-0.1, terrain_spline_38, 0.0),
  (0.03, terrain_spline_42, 0.0),
  (0.06, terrain_spline_46, 0.0),
])

///|
let terrain_spline_48 : TerrainSpline = Curve(Weirdness, [
  (-0.01, Constant(0.63), 0.0),
  (0.01, Constant(0.3), 0.0),
])

///|
let terrain_spline_49 : TerrainSpline = Curve(Ridges, [
  (0.19999999, Constant(0.0), 0.0),
  (0.44999996, Constant(0.0), 0.0),
  (1.0, terrain_spline_48, 0.0),
])

///|
let terrain_spline_50 : TerrainSpline = Curve(Weirdness, [
  (-0.01, Constant(0.315), 0.0),
  (0.01, Constant(0.15), 0.0),
])

///|
let terrain_spline_51 : TerrainSpline = Curve(Ridges, [
  (0.19999999, Constant(0.0), 0.0),
  (0.44999996, Constant(0.0), 0.0),
  (1.0, terrain_spline_50, 0.0),
])

///|
let terrain_spline_52 : TerrainSpline = Curve(Erosion, [
  (-1.0, terrain_spline_49, 0.0),
  (-0.78, terrain_spline_51, 0.0),
  (-0.5775, terrain_spline_51, 0.0),
  (-0.375, Constant(0.0), 0.0),
])

///|
let terrain_spline_53 : TerrainSpline = Curve(Ridges, [
  (0.19999999, Constant(0.0), 0.0),
  (0.44999996, terrain_spline_48, 0.0),
  (1.0, terrain_spline_48, 0.0),
])

///|
let terrain_spline_54 : TerrainSpline = Curve(Erosion, [
  (-1.0, terrain_spline_53, 0.0),
  (-0.78, terrain_spline_49, 0.0),
  (-0.5775, terrain_spline_49, 0.0),
  (-0.375, Constant(0.0), 0.0),
])

///|
let terrain_spline_55 : TerrainSpline = Curve(Continents, [
  (-0.11, Constant(0.0), 0.0),
  (0.03, terrain_spline_52, 0.0),
  (0.65, terrain_spline_54, 0.0),
])

///|
let terrain_offset_spline : TerrainSpline = terrain_spline_28

///|
let terrain_factor_spline : TerrainSpline = terrain_spline_47

///|
let terrain_jaggedness_spline : TerrainSpline = terrain_spline_55
