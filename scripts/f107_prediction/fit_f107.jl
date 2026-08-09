## Description #############################################################################
#
# This file generates the coefficients to predict the F10.7 solar flux index for the
# satellite decay analysis. It fits the data from 1957 up to today considering the following
# model:
#
# F̄₁₀.₇ = F₀ +     ∑      aᵢ ⋅ sin(2π ⋅ i ⋅ (t - t₀) / P) + bᵢ ⋅ cos(2π ⋅ i ⋅ (t - t₀) / P),
#              i ∈ [1, 6]
#
# where `t₀` is the reference day (1957-10-02) represented in Julian day. The fitting
# coefficients are:
#
# - `F₀`: the mean value of the F10.7 index.
# - `aᵢ`: the sine coefficients for the i-th harmonic.
# - `bᵢ`: the cosine coefficients for the i-th harmonic.
# - `P`:  the period of the solar cycle.
#
# The output is stored in a CSV file with the following columns:
#
#     t₀, F₀, P, a₁, a₂, a₃, a₄, a₅, a₆, b₁, b₂, b₃, b₄, b₅, b₆
#
# This model was based on the information available in [1].
#
## References ##############################################################################
#
# [1] D. Whitlock (2006). "Modeling the Effect of High Solar Activity on the Orbital Debris
#     Environment", Orbital Debris Quarterly News, vol. 10, n. 2, April, 2006.
#
############################################################################################

using Dates
using LsqFit
using Printf
using SpaceIndices

############################################################################################
#                                          Model                                           #
############################################################################################

"""
    f107_model(vt::AbstractVector, p::AbstractVector, t₀::Number) -> Vector{Float64}

Compute the modeled F10.7 index [sfu] at the instants `vt` [Julian day] using the harmonic
model parameters `p` and the reference epoch `t₀` [Julian day].

The function throws if `p` does not have exactly 14 elements.

# Arguments

- `vt::AbstractVector`: Instants [Julian day] at which the model must be evaluated.
- `p::AbstractVector`: Model parameters organized as follows:
    - `p[1]`: Mean F10.7 index `F₀` [sfu].
    - `p[2]`: Solar cycle period `P` [day].
    - `p[3:8]`: Sine coefficients `a₁` to `a₆` [sfu].
    - `p[9:14]`: Cosine coefficients `b₁` to `b₆` [sfu].
- `t₀::Number`: Reference epoch [Julian day].

# Returns

- `Vector{Float64}`: Modeled F10.7 index [sfu] at each instant in `vt`.
"""
function f107_model(vt::AbstractVector, p::AbstractVector, t₀::Number)
    length(p) == 14 ||
        throw(ArgumentError("The parameter vector `p` must have 14 elements."))

    F₀ = p[1]
    P  = p[2]
    a  = @view p[3:8]
    b  = @view p[9:14]
    Δt̄ = @. (vt - t₀) / P

    r = fill(float(F₀), length(vt))

    @inbounds for i in 1:6
        @. r += a[i] * sin(2π * i * Δt̄) + b[i] * cos(2π * i * Δt̄)
    end

    return r
end

############################################################################################
#                                         Printing                                         #
############################################################################################

"""
    print_header(title::String) -> Nothing

Print `title` inside a rounded box to mark the beginning of the process output.
"""
function print_header(title::String)
    width = 78
    printstyled("╭", "─"^(width - 2), "╮\n"; color = :cyan)
    printstyled("│"; color = :cyan)
    printstyled(" " * rpad(title, width - 3); bold = true)
    printstyled("│\n"; color = :cyan)
    printstyled("╰", "─"^(width - 2), "╯\n"; color = :cyan)
    return nothing
end

"""
    print_info(msg::String) -> Nothing

Print the informative message `msg` aligned with the step descriptions.
"""
function print_info(msg::String)
    printstyled("    ↳ ", msg, "\n"; color = :light_black)
    return nothing
end

"""
    run_step(f::Function, description::String) -> Any

Execute the function `f`, printing `description` before the execution and a check mark
together with the elapsed time [s] after the completion. Return the result of `f()`.
"""
function run_step(f::Function, description::String)
    printstyled("  ● "; color = :cyan, bold = true)
    print(rpad(description * " ", 64, '.'), " ")
    t₀ = time()
    result = f()
    Δt = time() - t₀
    printstyled("✔"; color = :green, bold = true)
    printstyled(@sprintf(" %6.1f s\n", Δt); color = :light_black)
    return result
end

"""
    print_fit_summary(fit, rmse::Number) -> Nothing

Print the convergence status, the fitted parameters in `fit`, and the root-mean-square
error `rmse` [sfu] of the residuals.
"""
function print_fit_summary(fit, rmse::Number)
    F₀ = fit.param[1]
    P  = fit.param[2]
    a  = @view fit.param[3:8]
    b  = @view fit.param[9:14]

    println()
    printstyled("  Fit Summary\n"; bold = true)
    printstyled("  ", "─"^74, "\n"; color = :light_black)

    if fit.converged
        printstyled("    Status ...... "; color = :light_black)
        printstyled("converged\n"; color = :green, bold = true)
    else
        printstyled("    Status ...... "; color = :light_black)
        printstyled("NOT converged\n"; color = :red, bold = true)
    end

    printstyled("    F₀ .......... "; color = :light_black)
    @printf("%9.4f sfu\n", F₀)
    printstyled("    P ........... "; color = :light_black)
    @printf("%9.4f days (%.2f years)\n", P, P / 365.25)
    printstyled("    RMSE ........ "; color = :light_black)
    @printf("%9.4f sfu\n", rmse)

    println()
    printstyled("    i         aᵢ [sfu]      bᵢ [sfu]\n"; bold = true)
    printstyled("    ", "─"^33, "\n"; color = :light_black)

    for i in 1:6
        @printf("    %d    %13.4f %13.4f\n", i, a[i], b[i])
    end

    println()
    return nothing
end

############################################################################################
#                                         Fitting                                          #
############################################################################################

"""
    fit_curve(output_file::String) -> LsqFit.LsqFitResult

Fit the harmonic F10.7 prediction model to the Celestrak observed data from 1957-10-02 up
to today and write the resulting coefficients to the CSV file `output_file`.

The function prints a report of each step, warning if the least-squares fitting did not
converge. It returns the least-squares result, allowing further inspection of the fitted
parameters and residuals.

# Arguments

- `output_file::String`: Path of the output CSV file. Intermediate directories are created
    if they do not exist.
    (**Default**: `joinpath(@__DIR__, "f107_prediction_coefficients.csv")`)
"""
function fit_curve(
    output_file::String = joinpath(@__DIR__, "f107_prediction_coefficients.csv")
)
    print_header("F10.7 Prediction Coefficient Fitting")

    run_step("Initializing the space indices (Celestrak)") do
        SpaceIndices.init(SpaceIndices.Celestrak)
    end

    # == Obtain the Input Data =============================================================

    dt₀ = Date(1957, 10, 2)
    dt₁ = today()
    t₀  = datetime2julian(DateTime(dt₀))

    vt, vf107 = run_step("Fetching the F10.7 observations") do
        vdt = dt₀:Day(1):dt₁
        vt  = datetime2julian.(DateTime.(vdt))
        vt, space_index.(Val(:F10obs), vt)
    end

    print_info("$(length(vf107)) samples from $dt₀ to $dt₁.")

    # == Fit the Model =====================================================================

    F̄₀ = sum(vf107) / length(vf107)
    p₀ = vcat(F̄₀, 3900.0, fill(10.0, 12))

    fit = run_step("Fitting the 14-parameter harmonic model") do
        curve_fit((t, p) -> f107_model(t, p, t₀), vt, vf107, p₀)
    end

    rmse = √(sum(abs2, fit.resid) / length(fit.resid))
    print_fit_summary(fit, rmse)

    !fit.converged && @warn "The fitting did not converge. The output may be unreliable."

    # == Write the Output ==================================================================

    run_step("Writing the coefficients to the output file") do
        output_dir = dirname(output_file)
        !isempty(output_dir) && mkpath(output_dir)

        open(output_file, "w") do io
            println(io, "t₀, F₀, P, a₁, a₂, a₃, a₄, a₅, a₆, b₁, b₂, b₃, b₄, b₅, b₆")
            println(io, join([t₀; fit.param], ", "))
        end
    end

    print_info("Output file: $output_file")

    return fit
end

# The output file can be passed as the first command-line argument.
isempty(ARGS) ? fit_curve() : fit_curve(ARGS[1])
