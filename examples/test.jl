using Revise
using HigherOrderFoodwebs
using AnnotatedHypergraphs

hg  = nichemodel(10, 0.2)
fwm = FoodwebModel(hg)

self_loops = filter(isloop, interactions(fwm))
trophic = filter(!isloop, interactions(fwm))
