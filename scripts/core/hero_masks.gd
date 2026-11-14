class_name HeroMasks
## Made by tools/hero_masks.py. The usual color of each part of every built-in hero model,
## so the game can repaint it. Do not edit by hand.

const REFS := {
	"hero_f1_academy": {"skin": Color(0.9473, 0.5972, 0.4508), "hair": Color(0.491, 0.4969, 0.5333), "top": Color(0.0331, 0.0423, 0.1095), "bottom": Color(0.0953, 0.0976, 0.1196), "shoes": Color(0.0382, 0.0231, 0.016)},
	"hero_f1_heartland": {"skin": Color(0.9216, 0.5395, 0.4287), "hair": Color(0.4233, 0.4233, 0.4397), "top": Color(0.7835, 0.7913, 0.8308), "bottom": Color(0.007, 0.0091, 0.0343), "shoes": Color(0.807, 0.8228, 0.8388)},
	"hero_f1_rider": {"skin": Color(0.7305, 0.4794, 0.3564), "hair": Color(0.3231, 0.3516, 0.4287), "top": Color(0.013, 0.0152, 0.0185), "bottom": Color(0.0152, 0.016, 0.0168), "shoes": Color(0.011, 0.011, 0.0103)},
	"hero_f1_satellite": {"skin": Color(0.8714, 0.5972, 0.4793), "hair": Color(0.5776, 0.5841, 0.6445), "top": Color(0.0595, 0.0666, 0.0802), "bottom": Color(0.107, 0.1095, 0.0802), "shoes": Color(0.0194, 0.0395, 0.0395)},
	"hero_f1_street": {"skin": Color(0.6239, 0.3613, 0.2874), "hair": Color(0.402, 0.4341, 0.491), "top": Color(0.3613, 0.5333, 0.5648), "bottom": Color(0.006, 0.0081, 0.0117), "shoes": Color(0.4341, 0.5648, 0.6039)},
	"hero_f2_academy": {"skin": Color(0.8469, 0.4851, 0.3864), "hair": Color(0.0085, 0.0152, 0.0395), "top": Color(0.0144, 0.0212, 0.0613), "bottom": Color(0.093, 0.0953, 0.1144), "shoes": Color(0.0221, 0.0075, 0.007)},
	"hero_f2_rider": {"skin": Color(0.956, 0.6514, 0.4564), "hair": Color(0.0307, 0.0409, 0.0887), "top": Color(0.0344, 0.0409, 0.0409), "bottom": Color(0.0344, 0.0423, 0.0437), "shoes": Color(0.0296, 0.0356, 0.0369)},
	"hero_f2_street": {"skin": Color(0.8228, 0.4969, 0.3516), "hair": Color(0.0065, 0.0103, 0.0356), "top": Color(0.8228, 0.9046, 0.9131), "bottom": Color(0.0168, 0.0185, 0.0203), "shoes": Color(0.1274, 0.1356, 0.1559)},
	"hero_f3_street": {"skin": Color(0.9131, 0.5776, 0.4969), "hair": Color(0.5149, 0.4851, 0.5583), "top": Color(0.0185, 0.0185, 0.0194), "bottom": Color(0.0222, 0.0212, 0.0222), "shoes": Color(0.0331, 0.0284, 0.0369)},
	"hero_f4_street": {"skin": Color(0.9911, 0.5841, 0.3968), "hair": Color(0.0144, 0.0284, 0.0666), "top": Color(0.0931, 0.107, 0.117), "bottom": Color(0.491, 0.5029, 0.5776), "shoes": Color(0.807, 0.8632, 0.8714)},
	"hero_m1_academy": {"skin": Color(0.7991, 0.5149, 0.3763), "hair": Color(0.3967, 0.4397, 0.5029), "top": Color(0.016, 0.0262, 0.0648), "bottom": Color(0.1384, 0.1384, 0.1413), "shoes": Color(0.0319, 0.0203, 0.0123)},
	"hero_m1_heartland": {"skin": Color(0.807, 0.5149, 0.4179), "hair": Color(0.6514, 0.6654, 0.6654), "top": Color(0.5395, 0.5333, 0.7011), "bottom": Color(0.0003, 0.0056, 0.0232), "shoes": Color(0.5711, 0.5841, 0.6867)},
	"hero_m1_rider": {"skin": Color(0.6939, 0.4736, 0.3419), "hair": Color(0.3005, 0.305, 0.3095), "top": Color(0.0117, 0.0144, 0.0168), "bottom": Color(0.0091, 0.0123, 0.013), "shoes": Color(0.0081, 0.0085, 0.0103)},
	"hero_m1_satellite": {"skin": Color(0.8308, 0.491, 0.3231), "hair": Color(0.4342, 0.4397, 0.4564), "top": Color(0.0595, 0.0685, 0.0762), "bottom": Color(0.0595, 0.0666, 0.0452), "shoes": Color(0.013, 0.0123, 0.006)},
	"hero_m1_street": {"skin": Color(0.9216, 0.6172, 0.462), "hair": Color(0.5972, 0.6239, 0.6939), "top": Color(0.004, 0.0097, 0.0091), "bottom": Color(0.0019, 0.0052, 0.0273), "shoes": Color(0.8631, 0.9473, 0.9647)},
	"hero_m2_academy": {"skin": Color(0.723, 0.4341, 0.2705), "hair": Color(0.013, 0.0194, 0.0409), "top": Color(0.0144, 0.0231, 0.0528), "bottom": Color(0.1274, 0.1329, 0.147), "shoes": Color(0.0497, 0.0307, 0.0177)},
	"hero_m2_rider": {"skin": Color(0.7991, 0.5089, 0.2918), "hair": Color(0.0016, 0.0037, 0.0137), "top": Color(0.0307, 0.0296, 0.0284), "bottom": Color(0.0319, 0.0319, 0.0319), "shoes": Color(0.0284, 0.0284, 0.0273)},
	"hero_m2_street": {"skin": Color(0.7084, 0.4341, 0.2705), "hair": Color(0.016, 0.0221, 0.0528), "top": Color(0.1356, 0.153, 0.1811), "bottom": Color(0.0037, 0.0117, 0.013), "shoes": Color(0.7305, 0.8149, 0.8388)},
	"hero_m3_street": {"skin": Color(0.807, 0.4233, 0.305), "hair": Color(0.5457, 0.5647, 0.6376), "top": Color(0.0065, 0.0103, 0.013), "bottom": Color(0.0033, 0.007, 0.0284), "shoes": Color(0.9301, 0.9387, 0.9647)},
	"hero_m4_street": {"skin": Color(0.9131, 0.5776, 0.3663), "hair": Color(0.0048, 0.0123, 0.0423), "top": Color(0.0823, 0.1195, 0.1441), "bottom": Color(0.4342, 0.4793, 0.5395), "shoes": Color(0.807, 0.9047, 0.9387)},
}
