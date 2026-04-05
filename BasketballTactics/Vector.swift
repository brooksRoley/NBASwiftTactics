import Foundation

struct Vector2D {
    var x: Float
    var y: Float

    init(_ x: Float = 0, _ y: Float = 0) {
        self.x = x
        self.y = y
    }

    static func + (lhs: Vector2D, rhs: Vector2D) -> Vector2D {
        Vector2D(lhs.x + rhs.x, lhs.y + rhs.y)
    }

    static func - (lhs: Vector2D, rhs: Vector2D) -> Vector2D {
        Vector2D(lhs.x - rhs.x, lhs.y - rhs.y)
    }

    static func * (lhs: Vector2D, scalar: Float) -> Vector2D {
        Vector2D(lhs.x * scalar, lhs.y * scalar)
    }

    var magnitude: Float {
        sqrt(x * x + y * y)
    }

    var normalized: Vector2D {
        let mag = magnitude
        return mag > 0 ? Vector2D(x / mag, y / mag) : Vector2D()
    }

    func distance(to other: Vector2D) -> Float {
        (self - other).magnitude
    }
}

struct Vector3D {
    var x: Float
    var y: Float
    var z: Float

    init(_ x: Float = 0, _ y: Float = 0, _ z: Float = 0) {
        self.x = x
        self.y = y
        self.z = z
    }

    static func + (lhs: Vector3D, rhs: Vector3D) -> Vector3D {
        Vector3D(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }

    static func - (lhs: Vector3D, rhs: Vector3D) -> Vector3D {
        Vector3D(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
    }

    static func * (lhs: Vector3D, scalar: Float) -> Vector3D {
        Vector3D(lhs.x * scalar, lhs.y * scalar, lhs.z * scalar)
    }

    var magnitude: Float {
        sqrt(x * x + y * y + z * z)
    }
}
