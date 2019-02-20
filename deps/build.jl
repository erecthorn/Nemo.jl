#using Libdl

using BinaryProvider # requires BinaryProvider 0.3.0 or later

# Parse some basic command-line arguments
const verbose = true#"--verbose" in ARGS

# Dependencies that must be installed before this package can be built
if !Sys.iswindows()
	dependencies = [
		"https://github.com/JuliaMath/MPFRBuilder/releases/download/v4.0.1-3/build_MPFR.v4.0.1.jl",
		"https://github.com/JuliaMath/GMPBuilder/releases/download/v6.1.2-2/build_GMP.v6.1.2.jl",
		"https://github.com/thofma/Flint2Builder/releases/download/2baa9bc/build_flint2.v2.0.0-baa9bc74a7ce463058ecdfa1430c764b20d3e7e.jl",
		"https://github.com/thofma/ArbBuilder/releases/download/v0.2.16/build_arb.v2.16.0.jl",
		"https://github.com/thofma/AnticBuilder/releases/download/v0.2.0/build_antic.v0.2.0.jl"
	]
else
	dependencies = [
		"https://github.com/JuliaMath/GMPBuilder/releases/download/v6.1.2-2/build_GMP.v6.1.2.jl",
		"https://github.com/JuliaMath/MPFRBuilder/releases/download/v4.0.1-3/build_MPFR.v4.0.1.jl"
	]
end

const prefix = Prefix(get([a for a in ARGS if a != "--verbose"], 1, joinpath(@__DIR__, "usr")))

products = []

for url in dependencies
		build_file = joinpath(@__DIR__, basename(url))
		if !isfile(build_file)
				download(url, build_file)
		end
end

# Execute the build scripts for the dependencies in an isolated module to avoid overwriting
# any variables/constants here
for url in dependencies
		build_file = joinpath(@__DIR__, basename(url))
		m = @eval module $(gensym()); include($build_file); end
		append!(products, m.products)
end

ANTIC_VERSION = "ede86094503380648ce51fa56cd3ff16217cffed"
FLINT_VERSION = "34adb7359da4ca2ad2a86635e374bf711e520056"
ARB_VERSION = "fe53e3f306380b5a65b30dcec776e10428601790"

if Sys.iswindows()

	## download libpthreads
	println("Downloading libpthread ... ")
	if Int == Int32
		download("http://nemocas.org/binaries/w32-libwinpthread-1.dll", joinpath(prefix, "lib", "libwinpthread-1.dll"))
	else
		download("http://nemocas.org/binaries/w64-libwinpthread-1.dll", joinpath(prefix, "lib", "libwinpthread-1.dll"))
	end
  println("DONE")

   println("Downloading flint ... ")
   if Int == Int32
      download("http://nemocas.org/binaries/w32-libflint.dll", joinpath(prefix, "lib", "libflint.dll"))
   else
      download("http://nemocas.org/binaries/w64-libflint.dll.$FLINT_VERSION", joinpath(prefix, "lib", "libflint.dll"))
   end

   try
     run(`ln -sf $prefix\\lib\\libflint.dll $prefix\\lib\\libflint-13.dll`)
   catch
     cp(joinpath(prefix, "lib", "libflint.dll"), joinpath(prefix, "lib", "libflint-13.dll"), force = true)
   end

   if Int == Int32
      download("http://nemocas.org/binaries/w32-libarb.dll", joinpath(prefix, "lib", "libarb.dll"))
   else
      download("http://nemocas.org/binaries/w64-libarb.dll.$ARB_VERSION", joinpath(prefix, "lib", "libarb.dll"))
   end
   println("DONE")

   if Int == Int32
      download("http://nemocas.org/binaries/w32-libantic.dll", joinpath(prefix, "lib", "libantic.dll"))
   else
      download("http://nemocas.org/binaries/w64-libantic.dll.$ANTIC_VERSION", joinpath(prefix, "lib", "libantic.dll"))
   end
end

push!(Libdl.DL_LOAD_PATH, joinpath(prefix, "lib"))
