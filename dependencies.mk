# Assumes only SystemVerilog (.sv) files are used
# Format is:
#    Product : List of Dependencies (Use \ at the end of the line for line continuation)
#
# Types of products are:
#    *.rtl.json:  Simulation file
#    *.vcd:  Value Change Dump (signal trace)
#    *.ice40.jpg:  Ice40 synthesis
#    *.aig.jpg:  AIG synthesis
#    *.bin:  bitstream
#    *.edit: Open the preceeding file for editing
#    *.riscv-sim: Simulate the file (using launch.json view; Must config launch.json)
#    *.ice40.dot: Ice40 synthesis in dot format
#    *.rom.txt: Convert a single .s file to assembly format for RISC-V ROM (Does not sanity check; Will remove any lines between <RM> and </RM> tags)
# Products still in alpha testing:
#	 *.placed.svg : Placement data and file viewer (requires webserver be running to view)
#	 *.router.svg : Router data and file viewer (requires webserver be running to view)
#
# A line preceeding a target that starts with a comment can "override" the type of target or the label used in the task
#   With either/both label="..." or type="..." (Types include a dot for the extension, like .edit or .rtl.json)
#   A type of "edit" can be used to open the file in code.
#
# There are also global dependencies that can be used to launch common tasks independent of specific modules or projects:
#   The type="server" can be used to include a task for the FPGA server
#   The type="rebuild" can be usd to include a task for rebuilding the tasks themselves (still need to be refreshed)


# Common global-level dependencies:

# label="FPGA Image Server" type="server"
server:

# label="Rebuild Tasks" type="rebuild" hide="true"
rebuild:


# # label="Refresh Tasks" type="refresh"
# refresh:


# Not needed here, but no harm...
.PHONY: server rebuild

# Projects are typically contained in a subdirectory
# The "products" folders are hidden (by default due to the devcontainer.json configuration) and normally are
# used to hold the files generated for a target.

# label="100.0 Edit questions.md" type=".edit"
questions.md.edit:


