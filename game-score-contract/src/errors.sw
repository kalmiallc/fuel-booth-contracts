library;


pub enum SetError {
    ValueAlreadySet: (),

    UsernameExists: (),
    UsernameAlreadyUsedEmail: (),
}
pub enum GetError {
    UsernameDoesNotExists: (),
    IdIsOverMax: (),
}
