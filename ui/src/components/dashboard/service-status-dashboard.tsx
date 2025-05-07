"use client"

import { CheckCircle, AlertCircle, AlertTriangle } from "lucide-react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"

export function ServiceStatusDashboard() {
  // Generate dates for the last 7 days
  const generateDates = () => {
    const dates = []
    const today = new Date()

    for (let i = 7; i >= 1; i--) {
      const date = new Date()
      date.setDate(today.getDate() - (7 - i))
      dates.push({
        day: i,
        label: `Mar ${i}`,
      })
    }

    return dates.reverse()
  }

  const dates = generateDates()

  const services = [
    { name: "API Gateway", statuses: generateRandomStatuses() },
    { name: "Authentication", statuses: generateRandomStatuses() },
    { name: "Backup Services", statuses: generateRandomStatuses() },
    { name: "Data Processing", statuses: generateRandomStatuses(true) },
    { name: "Logging Service", statuses: generateRandomStatuses() },
    { name: "Monitoring", statuses: generateRandomStatuses() },
    { name: "Notification Service", statuses: generateRandomStatuses() },
  ]

  function generateRandomStatuses(includeIssues = false) {
    const statuses: ("normal" | "degraded" | "disrupted")[] = []
    for (let i = 0; i < 7; i++) {
      if (includeIssues && (i === 2 || i === 4)) {
        statuses.push(i === 2 ? "degraded" : "disrupted")
      } else {
        statuses.push("normal")
      }
    }
    return statuses
  }

  // Count services by status
  const statusCounts = {
    normal: services.filter(
      (service) => service.statuses.every((status) => status === "normal") && service.statuses.length > 0,
    ).length,
    degraded: services.filter((service) => service.statuses.some((status) => status === "degraded")).length,
    disrupted: services.filter((service) => service.statuses.some((status) => status === "disrupted")).length,
  }

  return (
    <div className="grid gap-4">
      <div className="grid gap-4 md:grid-cols-3">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Operational Services</CardTitle>
            <CheckCircle className="h-4 w-4 text-green-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{statusCounts.normal}</div>
            <p className="text-xs text-muted-foreground">All services functioning normally</p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Degraded Services</CardTitle>
            <AlertTriangle className="h-4 w-4 text-orange-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{statusCounts.degraded}</div>
            <p className="text-xs text-muted-foreground">Services experiencing performance issues</p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Disrupted Services</CardTitle>
            <AlertCircle className="h-4 w-4 text-red-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{statusCounts.disrupted}</div>
            <p className="text-xs text-muted-foreground">Services currently unavailable</p>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Service Status History</CardTitle>
          <CardDescription>Up-to-the-minute service availability and performance information</CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="w-[180px]">Service</TableHead>
                <TableHead className="text-center">Current Status</TableHead>
                {dates.map((date) => (
                  <TableHead key={date.day} className="text-center">
                    Mar {date.day}
                  </TableHead>
                ))}
              </TableRow>
            </TableHeader>
            <TableBody>
              {services.map((service, index) => (
                <TableRow key={index}>
                  <TableCell className="font-medium">{service.name}</TableCell>
                  <TableCell className="text-center">
                    <StatusIndicator status="normal" />
                  </TableCell>
                  {service.statuses.map((status, i) => (
                    <TableCell key={i} className="text-center">
                      <StatusIndicator status={status} />
                    </TableCell>
                  ))}
                </TableRow>
              ))}
            </TableBody>
          </Table>

          <div className="mt-6 flex items-center gap-6">
            <div className="flex items-center gap-2">
              <StatusIndicator status="normal" />
              <span className="text-sm">Normal</span>
            </div>
            <div className="flex items-center gap-2">
              <StatusIndicator status="disrupted" />
              <span className="text-sm">Disruption</span>
            </div>
            <div className="flex items-center gap-2">
              <StatusIndicator status="degraded" />
              <span className="text-sm">Degradation</span>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

function StatusIndicator({ status }: { status: "normal" | "disrupted" | "degraded" }) {
  if (status === "normal") {
    return <CheckCircle className="h-5 w-5 text-green-500 mx-auto" />
  } else if (status === "disrupted") {
    return <AlertCircle className="h-5 w-5 text-red-500 mx-auto" />
  } else {
    return <AlertTriangle className="h-5 w-5 text-orange-500 mx-auto" />
  }
}