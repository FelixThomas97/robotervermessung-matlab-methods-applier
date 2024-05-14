function [distance, param] = MinDistParam(x1, x2, y)
    Epsilon = 0.000001;
    dx = x2 - x1;
    dy = y - x1;
    dxy = (dot(dy, dx) / norm(dx)^2) * dx;
    angle = dot(dx, dxy) / (norm(dx) * norm(dxy));
    % assert(dot(dy, dx) == 0 || (NearlyEqual(angle, 1, Epsilon) || NearlyEqual(angle, -1, Epsilon)), 'Assertion failed: dot(a, b) == 0 || (NearlyEqual(angle, 1, Epsilon) || NearlyEqual(angle, -1, Epsilon))');

    if dot(dy, dx) == 0 || angle < 0
        param = 0;
        distance = norm(dy);
    else
        param = norm(dxy) / norm(dx);
        if param > 1
            param = 1;
            distance = norm(y - x2);
        else
            distance = norm(y - (x1 + dxy));
        end
    end
end


