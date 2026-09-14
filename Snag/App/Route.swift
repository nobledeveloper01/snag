// Where the list can go. One path, owned by the list, so sealing a draft
// can replace the walk with the sealed screen instead of stacking on it.
enum Route: Hashable {
    case draft(String)
    case sealed(String)
}
