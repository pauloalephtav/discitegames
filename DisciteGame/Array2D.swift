

// Cria um Array de 2 dimensoes
// Array generico (aceita elementos de qualquer tipo T)
struct Array2D<T> {
    
    let columns: Int
    let rows: Int
    
    private var array: Array<T?>
    
    init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
        array = Array<T?>(count: rows*columns, repeatedValue: nil)
    }
    
    subscript(column: Int, row: Int) -> T? {
        get {
            return array[row*columns + column]
        }
        set {
            return array[row*columns + column] = newValue
        }
    }
    
}