using Prometheus;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
app.UseSwagger();
app.UseSwaggerUI();

app.UseCors("AllowAll");
app.UseHttpMetrics();

// Health check endpoint
app.MapGet("/health", () => new { status = "healthy", service = "backend-api", timestamp = DateTime.UtcNow })
   .WithName("HealthCheck")
   .WithOpenApi();

// API endpoints
app.MapGet("/api/status", () => new 
{ 
    service = "Backend API",
    version = "1.0.0",
    environment = app.Environment.EnvironmentName,
    timestamp = DateTime.UtcNow
})
.WithName("GetStatus")
.WithOpenApi();

app.MapGet("/api/data", () => 
{
    var data = Enumerable.Range(1, 10).Select(i => new 
    {
        id = i,
        name = $"Item {i}",
        value = Random.Shared.Next(1, 100),
        createdAt = DateTime.UtcNow.AddDays(-i)
    }).ToArray();
    
    return new { count = data.Length, items = data };
})
.WithName("GetData")
.WithOpenApi();

// Prometheus metrics endpoint
app.MapMetrics();

app.Run();
