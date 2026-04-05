import Foundation

class Basketball {
    var position = Vector3D()
    var velocity = Vector3D()
    var isPossessed = false
    var possessorId: Int = -1

    func updatePhysics(deltaTime: Float) {
        guard !isPossessed else { return }
        position = position + (velocity * deltaTime)
        if position.z > 0 {
            velocity.z -= 9.8 * deltaTime
        } else {
            position.z = 0
            velocity.z = -velocity.z * 0.6
        }
    }
}
