library;


pub enum SetError {
    ValueAlreadySet: (),

    UsernameExists: (),
}
pub enum GetError {
    IdIsOverMax: (),
}
