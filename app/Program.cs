using Prometheus;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorPages();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

// Exponer métricas de Prometheus
app.UseHttpMetrics();

app.UseAuthorization();

app.MapRazorPages();

// Endpoint de métricas
app.MapMetrics();

app.Run();

public partial class Program { }
