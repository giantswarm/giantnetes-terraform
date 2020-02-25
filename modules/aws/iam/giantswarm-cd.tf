# role for conveyor jobs

resource "aws_iam_role" "giantswarm-cd" {
  name               = "GiantSwarmCD"
  description        = "Role for Giant Swarm continuous delivery system."
  assume_role_policy = "${data.aws_iam_policy_document.giantswarm-cd-assume-role-policy.json}"
}

# attach AWS-managed AdministratorAccess policy - this could be cut down
# to a custom policy with only the required access level.
resource "aws_iam_role_policy_attachment" "giantswarm-cd-admin-access" {
    role               = "${aws_iam_role.giantswarm-cd.name}"
    policy_arn         = "arn:aws:iam::aws:policy/AdministratorAccess"
}
