// Declare a module named 'library'
library;

// Define an enum called 'SetError' to represent different types of errors that can occur
pub enum SetError {
    // Error indicating that a value has already been set
    ValueAlreadySet: (),

    // Error indicating that the username already exists
    UsernameExists: (),

    // Error indicating that the username is already associated with an email
    UsernameAlreadyUsedEmail: (),
}

// Define another enum called 'GetError' to represent errors that can occur during retrieval
pub enum GetError {
    // Error indicating that the username does not exist
    UsernameDoesNotExists: (),

    // Error indicating that the index is over the maximum allowed value
    IndexIsOverMax: (),
}
