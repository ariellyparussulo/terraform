output "vpc_id" {
    value = aws_vpc.default.id
}

output "nat_security_group" {
    value = aws_security_group.nat.id
}

output "private_subnet" {
    value = aws_subnet.private.id
}

output "public_subnet" {
    value = aws_subnet.public.id
}