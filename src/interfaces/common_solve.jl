# This is _real_ lazy. TODO actually impletment this interface properly Also
# implement Solution type with accomodations for the food web and flux stuff.

function CommonSolve.solve(fwm::FoodwebModel, args...; kwargs...)

    if ismissing(fwm.odes)

        fwm = build_ode_system(fwm)
    end
    
    solve(fwm.odes, args...; kwargs...)
end