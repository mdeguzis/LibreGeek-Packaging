
cat<<- EOF > hello_world.rs
// This is a comment, and will be ignored by the compiler
// You can test this code by clicking the "Run" button over there ->
// or if prefer to use your keyboard, you can use the "Ctrl + Enter" shortcut

// This code is editable, feel free to hack it!
// You can always return to the original code by clicking the "Reset" button ->

// This is the main function
fn main() {
    // The statements here will be executed when the compiled binary is called

    // Print text to the console
    println!("Hello World!");
}
EOF

# Generate rust binary
if ! rustc hellow_world.rs; then

	echo -e "Rust binary generation failed!"
	exit 1
	
else

	echo -e "Binary generation passed"
	
fi

# Run binary
if ! ./hello_world; then

	echo -e "Failed to execute rustc test binary"
	
else

	echo -e "Binary execution successful"
	
fi
