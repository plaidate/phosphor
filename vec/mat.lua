-- Phosphor core: 3x3 orientation matrices for full-attitude 3D.
--
-- Proj.model rotates a model about Y only — enough for ground games where
-- everything stands upright. Free-flight games (ships tumbling in space) need
-- objects at any attitude, so an object carries an orientation matrix here and
-- Proj.mesh draws it. Matrices are flat row-major 9-arrays:
--
--     { m11, m12, m13,
--       m21, m22, m23,
--       m31, m32, m33 }
--
-- Read column j as the object's local axis j expressed in the parent frame:
-- column 3 (m13,m23,m33) is where the object's nose (+Z) points. A vector is
-- transformed parent = M * local.

Mat = {}

function Mat.identity()
    return { 1, 0, 0, 0, 1, 0, 0, 0, 1 }
end

-- parent-space vector for a local (x,y,z): returns x', y', z'
function Mat.mulVec(m, x, y, z)
    return m[1] * x + m[2] * y + m[3] * z,
           m[4] * x + m[5] * y + m[6] * z,
           m[7] * x + m[8] * y + m[9] * z
end

-- matrix product a*b (both 9-arrays), returns a new 9-array
function Mat.mul(a, b)
    return {
        a[1] * b[1] + a[2] * b[4] + a[3] * b[7],
        a[1] * b[2] + a[2] * b[5] + a[3] * b[8],
        a[1] * b[3] + a[2] * b[6] + a[3] * b[9],
        a[4] * b[1] + a[5] * b[4] + a[6] * b[7],
        a[4] * b[2] + a[5] * b[5] + a[6] * b[8],
        a[4] * b[3] + a[5] * b[6] + a[6] * b[9],
        a[7] * b[1] + a[8] * b[4] + a[9] * b[7],
        a[7] * b[2] + a[8] * b[5] + a[9] * b[8],
        a[7] * b[3] + a[8] * b[6] + a[9] * b[9],
    }
end

-- rotation matrices (right-handed, angle in radians) about each parent axis
function Mat.rx(t)
    local s, c = math.sin(t), math.cos(t)
    return { 1, 0, 0, 0, c, -s, 0, s, c }
end

function Mat.ry(t)
    local s, c = math.sin(t), math.cos(t)
    return { c, 0, s, 0, 1, 0, -s, 0, c }
end

function Mat.rz(t)
    local s, c = math.sin(t), math.cos(t)
    return { c, -s, 0, s, c, 0, 0, 0, 1 }
end

-- premultiply m by a rotation about a parent axis: returns rot(t) * m, i.e. the
-- orientation after rotating it by t in the parent frame. Pitch is rx, roll rz.
function Mat.spinX(m, t) return Mat.mul(Mat.rx(t), m) end
function Mat.spinY(m, t) return Mat.mul(Mat.ry(t), m) end
function Mat.spinZ(m, t) return Mat.mul(Mat.rz(t), m) end

-- Re-orthonormalize to shed the rounding drift that accumulates when a matrix
-- is spun every frame (Elite's TIDY). Gram-Schmidt anchored on column 3 (nose).
function Mat.tidy(m)
    -- nose = column 3
    local nx, ny, nz = m[3], m[6], m[9]
    local nl = math.sqrt(nx * nx + ny * ny + nz * nz)
    if nl < 1e-6 then return Mat.identity() end
    nx, ny, nz = nx / nl, ny / nl, nz / nl
    -- right = column 1, made orthogonal to nose
    local rx, ry, rz = m[1], m[4], m[7]
    local d = rx * nx + ry * ny + rz * nz
    rx, ry, rz = rx - d * nx, ry - d * ny, rz - d * nz
    local rl = math.sqrt(rx * rx + ry * ry + rz * rz)
    if rl < 1e-6 then return Mat.identity() end
    rx, ry, rz = rx / rl, ry / rl, rz / rl
    -- up = nose x right (column 2)
    local ux = ny * rz - nz * ry
    local uy = nz * rx - nx * rz
    local uz = nx * ry - ny * rx
    return { rx, ux, nx, ry, uy, ny, rz, uz, nz }
end
